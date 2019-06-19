
#these are functions to be exported and visible to the user

#todo - Get-VHDSummary, Get-VMLastUse, New-HyperVReport

Function Set-VMNote {
    [CmdletBinding(DefaultParameterSetName = 'Name', SupportsShouldProcess)]
    [OutputType("none", "VirtualMachine")]
    Param(

        [Parameter(ParameterSetName = 'VMObject', Mandatory, Position = 0, ValueFromPipeline, HelpMessage = "A Hyper-V virtual machine object.")]
        [ValidateNotNullOrEmpty()]
        [Microsoft.HyperV.PowerShell.VirtualMachine[]]$VM,

        [Parameter(ParameterSetName = 'Name', Mandatory, Position = 0, ValueFromPipeline, HelpMessage = "Enter the name of a virtual machine.")]
        [Alias('VMName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(HelpMessage = "Enter the text for the note.")]
        [string]$Notes,

        [Parameter(HelpMessage = "Specify what action to take with the note.")]
        [ValidateSet("Create", "Append", "Clear")]
        [string]$Action = "Create",

        [Parameter(HelpMessage = "Write the VM object to the pipeline.")]
        [switch]$Passthru,

        [Parameter(ParameterSetName = 'Name', HelpMessage = "Enter the name of a Hyper-V host. The default is the localhost.")]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME

    )
    DynamicParam {
    #allow an alternate credential for remote servers
        if ($Computername -ne $env:computername -OR $vm[0].computername -ne $env:computername) {

            #define a parameter attribute object
            $attributes = New-Object System.Management.Automation.ParameterAttribute
            $attributes.HelpMessage = "Enter an alternate credential in the form domain\username or computername\username. If you used a credential to get the VM in any way, then you need to re-use it to set the note."

            #define a collection for attributes
            $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($attributes)

            #define the dynamic param
            $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Credential", [PSCredential], $attributeCollection)
            $dynParam1.Value = [System.Management.Automation.PSCredential]::Empty

            #create array of dynamic parameters
            $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add("Credential", $dynParam1)

            #use the array
            return $paramDictionary
        }

    }


    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"


        #define a scriptblock to run remotely
        $sb = {
            #uncomment the Write-Host lines for troubleshooting
            #write-host "In scriptblock" -ForegroundColor cyan
            #write-Host "Getting WMI VM object for $($using:vname)" -ForegroundColor green
            try {
                $data = Get-WmiObject -Namespace root/virtualization/v2 -Class msvm_VirtualSystemSettingData -filter "ElementName='$using:VName'" -ErrorAction stop
                if (-Not $data.ElementName) {
                    Throw "Item not found"
                }
            }
            catch {
                Write-Warning "Failed to get VirtualSystemSettingData for $($using:vname). $($_.exception.message)."
                #bail out
                return
            }
            if ($using:action -eq 'Clear') {
                #write-host "Clear" -ForegroundColor cyan
                $data.Notes = ""
            }
            elseif ($using:action -eq 'Append') {
                #write-host "append" -ForegroundColor cyan
                if (([regex]"\w+").ismatch($data.notes)) {
                    #get the existing array
                    #write-host "Using existing array" -ForegroundColor cyan
                    $vmnotes = $data.notes.trim() -as [array]
                }
                else {
                    #initialze a new one
                    #write-host "Initializing a new one" -ForegroundColor cyan
                    $vmnotes = @()
                }

                $vmnotes += $using:Notes
                $data.Notes = $vmNotes | Out-String
            }
            else {
                #write-host "create" -ForegroundColor Cyan
                $data.Notes = $using:Notes | Out-String
            }

            #Write-Host "Apply changes" -ForegroundColor cyan
            $text = $data.GetText("CimDtd20")
            $vmms = Get-WmiObject -Namespace root/virtualization/v2 -Classname msvm_virtualsystemmanagementservice
            $vmms.ModifySystemSettings($text)
        } #close scriptblock

        #define parameters to splat to Invoke-Command
        $runParams = @{
            ErrorAction = "Stop"
            Session     = $null
            Scriptblock = $sb
        }
    } #begin

    Process {

        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Using parameter set $($pscmdlet.ParameterSetName)"
        if (-Not $PSSess) {
            #create a PSSession to the remote computer if it doesn't already exist
            #it is assumed all VMs are on the same Hyper-V host
            if ($pscmdlet.ParameterSetName -eq "name") {
                $vmhost = $Computername
            }
            else {
                $vmhost = $VM[0].computername
            }
            $newps = @{
                ErrorAction  = "Stop"
                Computername = $vmHost
            }
            if ($credential) {
                $newps.Add("Credential", $Credential)
            }
            Try {
                if ($pscmdlet.ShouldProcess($vmhost, "Create PSSession")) {
                    $pssess = New-PSSession @newps
                }
            }
            Catch {
                Throw $_
            }
            $runParams.session = $PSSess
        }

        #define a collection of objects to process based on the detected parameter set
        if ($PSCmdlet.ParameterSetName -eq "VMObject") {
            $collection = $VM
        }
        else {
            $collection = $Name
        }
        #loop through each item in the collection which will be either a VM object or the name of a VM
        foreach ($item in $collection) {
            if ($item.name) {
                $vname = $item.name
            }
            else {
                $vname = $item
            }

            if ($pscmdlet.shouldprocess($vname, "$Action note(s)")) {
                #write-verbose ($runParams | Out-string)
                $r = Invoke-Command @runParams
                if ($r -AND $r.returnValue -ne 0) {
                    Write-Warning "Setting the note for $vmname on $($pssess.computername) failed. Return value is $($r.returnvalue)."
                }
                if ($passthru) {
                    Invoke-Command {Get-VM $using:vname} -session $pssess
                }
            }
        } #foreach vmobject

    } #process

    End {
        if ($PSSess) {
            Write-Verbose "[$((Get-Date).TimeofDay) END    ] Removing PSSession"
            Remove-PSSession -session $PSsess
        }
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end

} #close Set-VMNote
Function Expand-VMGroup {
    [cmdletbinding()]
    [outputtype("myGroupVM", "String")]

    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]$Name,
        [ValidateNotNullorEmpty()]
        [string]$Computername = $ENV:COMPUTERNAME,
        [pscredential]$Credential,
        [ValidateSet("VMCollectionType", "ManagementCollectionType")]
        [string]$GroupType,
        [switch]$List
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting VMGroups from $Computername"
        if ($Name) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Filtering groups by name: $Name"
        }

        #remove these from psboundparameters
        "list", "grouptype" | foreach-object {
            if ($PSBoundParameters.ContainsKey($_)) {
                [void]$PSBoundParameters.remove($_)
            }
        }
        Try {
            $groups = Get-VMGroup @PSBoundParameters -ErrorAction stop
            if ($GroupType) {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Filtering groups by type: $GroupType"
                $groups = $groups.where( {$_.GroupType -eq $GroupType})
            }
        }
        Catch {
            throw $_
        }
        if ($Groups) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Found $($groups.count) matching VM group(s)"
            #initialize an array to keep track of vm names.
            $names = @()
            foreach ($group in $groups) {
                if ($group.grouptype -eq 'ManagementCollectionType') {
                    $members = $group.VMGroupMembers.VMMembers
                }
                else {
                    $members = $group.VMMembers
                }

                foreach ($item in $members) {
                    if ($List) {
                        #only write the VMName to the pipeline
                        #if it hasn't been used before
                        if ($names -notcontains $item.name) {
                            $item.name
                        }
                        $names += $item.name
                    }
                    else {
                        #write a custom object to the pipeline
                        [pscustomobject]@{
                            PSTypeName   = "myGroupVM"
                            VMGroup      = $group.name
                            Name         = $item.name
                            State        = $item.State
                            Uptime       = $item.Uptime
                            Status       = $item.Status
                            Computername = $item.Computername
                        }
                    } #else
                } #foreach item

            } #foreach Group
        } #if
        else {
            Write-Warning "No matching VM Groups found."
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end

} #close Expand-VMGroup

Function Start-VMGroup {
    [cmdletbinding(SupportsShouldProcess)]
    [Outputtype("None", "Microsoft.HyperV.PowerShell.VirtualMachine", "Microsoft.HyperV.PowerShell.Commands.VmJob")]
    Param(
        [Parameter(Position = 0, ValueFromPipeline, HelpMessage = "The name of your VM Group")]
        [string]$Name,
        [ValidateNotNullorEmpty()]
        [string]$Computername = $ENV:COMPUTERNAME,
        [pscredential]$Credential,
        [switch]$AsJob,
        [switch]$Passthru
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        #create a copy of original psboundparameters that can be used later
        $original = ($PSBoundParameters -as [hashtable]).clone()
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting VMGroup $Name on $Computername"
        #remove these from psboundparameters
        "asjob", "passthru", "whatif", "confirm" | foreach-object {
            if ($PSBoundParameters.ContainsKey($_)) {
                [void]$PSBoundParameters.remove($_)
            }
        }

        Try {
            $groups = Get-VMGroup @PSBoundParameters -ErrorAction stop
        }
        Catch {
            throw $_
        }
        if ($Groups) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Found $($groups.count) matching group(s)"
            foreach ($group in $groups) {
                if ($group.grouptype -eq 'ManagementCollectionType') {
                    $members = $group.VMGroupMembers.VMMembers
                }
                else {
                    $members = $group.VMMembers
                }

                $members.where( {$_.state -ne 'running'}) | ForEach-Object {
                    Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Starting $($_.name)"
                    $original.Name = $_.Name
                    Start-VM @original
                }
            }
        }
        else {
            Write-Warning "No matching VM Groups found."
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end

} #close Start-VMGroup

Function Stop-VMGroup {
    [cmdletbinding(SupportsShouldProcess)]
    [Outputtype("None", "Microsoft.HyperV.PowerShell.VirtualMachine", "Microsoft.HyperV.PowerShell.Commands.VmJob")]
    Param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]$Name,
        [ValidateNotNullorEmpty()]
        [string]$Computername = $ENV:COMPUTERNAME,
        [pscredential]$Credential,
        [switch]$Force,
        [switch]$Save,
        [switch]$TurnOff,
        [switch]$AsJob,
        [switch]$Passthru
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
        #create a copy of original psboundparameters that can be used later
        $original = ($PSBoundParameters -as [hashtable]).clone()

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Getting VMGroup $Name on $Computername"

        #remove these from psboundparameters
        "force", "save", "asjob", "turnoff", "passthru", "whatif", "confirm" | ForEach-Object {
            if ($PSBoundParameters.ContainsKey($_)) {
                Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] removing boundparameter $_"
                [void]$PSBoundParameters.remove($_)
            }
        }
        Try {
            $groups = Get-VMGroup @PSBoundParameters -ErrorAction stop
        }
        Catch {
            throw $_
        }
        if ($Groups) {
            Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Found $($groups.count) matching group(s)"
            foreach ($group in $groups) {
                if ($group.grouptype -eq 'ManagementCollectionType') {
                    $members = $group.VMGroupMembers.VMMembers
                }
                else {
                    $members = $group.VMMembers
                }

                $members.where( {$_.state -eq 'running'}) | ForEach-Object {
                    $original.Name = $_.Name
                    Stop-VM @original
                }
            }
        }
        else {
            Write-Warning "No matching VM Groups found."
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end

} #close Stop-VMGroup

Function Find-VMGroup {

    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [Outputtype("Microsoft.HyperV.PowerShell.VMGroup")]
    Param(

        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [CimSession[]]$CimSession,

        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [pscredential[]]$Credential,

        [Parameter(ParameterSetName = 'Name', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'Id', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [guid]$Id,

        [ValidateSet("VMCollectionType", "ManagementCollectionType")]
        [string]$GroupType
    )

    Begin {

        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($MyInvocation.Mycommand)"
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Using parameter set $($PSCmdlet.ParameterSetName)"

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Hyper-V\Get-VMGroup', [System.Management.Automation.CommandTypes]::Cmdlet)
            if ($GroupType) {
                [void]$PSBoundParameters.Remove("GroupType")
                $scriptCmd = { & $wrappedCmd @PSBoundParameters | Where-Object {$_.Grouptype -eq $GroupType} }
            }
            else {
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Searching for VM group(s)"
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }

    } #process

    End {

        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($MyInvocation.Mycommand)"

        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }

    } #end

} #end function Find-VMGroup

Function Get-VMIPAddress {
    [cmdletbinding(DefaultParameterSetName = "computer")]
    [outputtype("vmIPAddress")]

    Param (
        [Parameter(Position = 0, Mandatory,
            HelpMessage = "Enter a Hyper-V virtual machine name",
            ValueFromPipeline, ValueFromPipelinebyPropertyName)]
        [ValidateNotNullorEmpty()]
        [alias("vm")]
        [object]$Name,
        [Parameter(ValueFromPipelinebyPropertyName, ParameterSetName = "computer")]
        [ValidateNotNullorEmpty()]
        [string]$Computername = $env:COMPUTERNAME,
        [Parameter(ParameterSetName = "computer")]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName = "session")]
        [Microsoft.Management.Infrastructure.CimSession]$Cimsession
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    } #begin

    Process {
        if ($name -is [string]) {
            Write-Verbose -Message "Getting virtual machine(s)."
            $vms = Get-VM @PSBoundParameters
        }
        else {
            $vms = $name
        }
        #otherwise we'll assume $Name is a virtual machine object
        foreach ($vm in $vms) {
            Write-Verbose -Message "Getting network information from $($vm.name)"
            $data = $vm | Get-VMNetworkAdapter -PipelineVariable pv |
                Select-Object -ExpandProperty IPAddresses -first 1 |
                Select-Object -first 1 -Property @{Name = "IP"; Expression = {$_}},
            @{Name = "Switch"; Expression = {$pv.SwitchName}},
            @{Name = "MAC"; Expression = {$pv.macaddress}}

            [pscustomobject]@{
                PSTypename   = "vmIPAddress"
                Name         = $vm.name
                IPAddress    = $data.IP
                MACAddress   = $data.mac
                Switch       = $data.Switch
                Computername = $vm.computername
            }
        } #foreach
    } #process

    End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end

} #end Get-VMIPAddress

Function Open-VMRemoteDesktop {
    [cmdletbinding()]
    [Outputtype("None")]

    Param(
        [Parameter(Position = 0, Mandatory,
            HelpMessage = "Enter a Hyper-V virtual machine name",
            ValueFromPipeline, ValueFromPipelinebyPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(ValueFromPipelinebyPropertyName)]
        [ValidateNotNullorEmpty()]
        [string]$Computername = $env:COMPUTERNAME,
        [switch]$Admin,
        [switch]$FullScreen
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    } #begin
    Process {
        Write-Verbose "Getting IP address for $Name on $Computername"
        $IPAddress = (Get-VMIPAddress -Name $Name -ComputerName $Computername).IPAddress
        #use the first address found for the virtual machine if more than one
        if ($IPAddress -is [array]) {
            $IPAddress = $IPAddress[0]
        }
        #define a command string which will eventually be turned into a scriptblock
        $cmd = "mstsc -v $IPAddress"
        if ($admin) {
            Write-Verbose "Adding /Admin"
            $cmd += " /Admin"
        }
        if ($FullScreen) {
            Write-Verbose "Adding /f for full screen"
            $cmd += " /f"
        }
        Write-Verbose -Message ("Connecting to {0} [{1}]" -f $Name, $IPAddress)
        #create a scriptblock from the $cmd string
        $sb = [scriptblock]::Create($cmd)
        Invoke-Command -ScriptBlock $sb
    } #process
    End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end

} #end Open-VMRemoteDesktop

Function Open-VMConnect {
    [cmdletbinding()]
    [outputtype("None")]

    Param(
        [Parameter(Position = 0, Mandatory,
            HelpMessage = "Enter a Hyper-V virtual machine name",
            ValueFromPipeline, ValueFromPipelinebyPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [string]$Computername = $env:computername
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    } #begin
    Process {

        $cmdstring = "vmconnect $computername '$name'"

        $cmd = [scriptblock]::Create($cmdstring)

        Write-Verbose -Message "Connecting to $name on $computername"
        Invoke-Command -ScriptBlock $cmd
    } #process
    End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end

} #end Open-VMConnect

Function Get-VHDSummary {
    Param()

    #get all virtual machines
    $vms = Get-VM

    foreach ($vm in $vms) {
        Write-Host "Getting drive info from $($vm.name)" -foregroundcolor Cyan
        #get the hard drives foreach virtual machine
        $vm.HardDrives | ForEach-Object {
            #a VM might have multiple drives so for each one get the VHD
            $vhd = Get-VHD -path $_.path

            <#
       $_ is the hard drive object so select a few properties and
       include properties from the VHD
      #>
            $_ | Select-Object -property VMName, Path,
            @{Name = "Type"; Expression = {$vhd.VhdType}},
            @{Name = "Format"; Expression = {$vhd.VhdFormat}},
            @{Name = "SizeGB"; Expression = {[math]::Round(($vhd.Size) / 1GB, 2)}},
            @{Name = "FileSizeGB"; Expression = {[math]::Round(($vhd.FileSize) / 1GB, 2)}}
        } #foreach
    } #foreach vm

} #end Get-VHDSummary

Function Get-VMState {
    <#
    this is a proxy function to the Hyper-V Get-VM that
    allows you to retrieve virtual machines by their state,
    i.e. stopped or running. The default is Running

    #>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    [outputtype("Microsoft.HyperV.PowerShell.VirtualMachine")]
    Param(

        [Parameter(ParameterSetName = 'Name', Position = 0, ValueFromPipeline)]
        [Alias('VMName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [CimSession[]]$CimSession,

        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [pscredential[]]$Credential,

        [Parameter(ParameterSetName = 'Id', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.Nullable[guid]]$Id,

        [Parameter(ParameterSetName = 'ClusterObject', Mandatory, Position = 0, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('Microsoft.FailoverClusters.PowerShell.ClusterObject')]
        [psobject]$ClusterObject,

        [Microsoft.HyperV.PowerShell.VMState]$State = 'Running'
    )

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Hyper-V\Get-VM', [System.Management.Automation.CommandTypes]::Cmdlet)
            [void]$PSBoundParameters.Remove('State')
            $scriptCmd = {& $wrappedCmd @PSBoundParameters | Where-Object state -eq $state }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

} #end Get-VMState

Function Get-VMMemorySummary {

    [CmdletBinding(DefaultParameterSetName = 'NamebyComputer')]
    [Outputtype("vmMemorySummary")]

    Param(

        [Parameter(ParameterSetName = 'NamebyComputer', Position = 0, ValueFromPipeline )]
        [Parameter(ParameterSetName = 'NamebySession')]
        [Alias('VMName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(ParameterSetName = "VM", ValueFromPipeline)]
        [Microsoft.HyperV.PowerShell.VirtualMachine[]]$VM,

        [Parameter(ParameterSetName = 'NamebySession')]
        [Parameter(ParameterSetName = 'IdbySession')]
        [ValidateNotNullOrEmpty()]
        [CimSession[]]$CimSession,

        [Parameter(ParameterSetName = 'NamebyComputer')]
        [Parameter(ParameterSetName = 'IdbyComputer')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'NamebyComputer')]
        [Parameter(ParameterSetName = 'IdbyComputer')]
        [ValidateNotNullOrEmpty()]
        [pscredential[]]$Credential,

        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'IdbySession')]
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'IdbyComputer')]
        [ValidateNotNull()]
        [System.Nullable[guid]]$Id

    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Using parameter set $($pscmdlet.ParameterSetName)"
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Retrieving virtual machines with these parameters"
        $psboundparameters | Out-String | Write-Verbose

        if ($pscmdlet.ParameterSetName -eq 'VM') {
            $vms = $VM
        }
        else {
            Try {
                $vms = Get-VM @psboundparameters
            }
            Catch {
                Throw $_
            }
        }

        #get memory values
        foreach ($vm in $vms) {

            $data = $vm | Get-VMMemory

            #all values are in MB
            [pscustomobject]@{
                PSTypeName   = "vmMemorySummary"
                Name         = $vm.Name
                Dynamic      = $vm.DynamicMemoryEnabled
                Assigned     = $vm.MemoryAssigned / 1MB
                Demand       = $vm.MemoryDemand / 1MB
                Startup      = $vm.MemoryStartup / 1MB
                Minimum      = $vm.MemoryMinimum / 1MB
                Maximum      = $vm.MemoryMaximum / 1MB
                Buffer       = $data.buffer
                Priority     = $data.priority
                Computername = $vm.ComputerName
                Date         = (Get-Date)
            } #custom object
        } #foreach VM

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

    } #end
} #end Get-VMMemorySummary

Function Get-VMLastUse {

    <#
.Synopsis
Find a virtual machine last use date.
.Description
This command will write a custom object to the pipeline which should indicate
when the virtual machine was last used. The command finds all hard drives that
are associated with a Hyper-V virtual machine and selects the first one. The
assumption is that if the virtual machine is running the hard drive file will
be changed and the first hard drive listed will most likely be the system drive.
The function retrieves the last write time property from the first VHD or VHDX
file to determine how long it has been since the file was last used. If the
virtual machine is currently running the last use time will be 0:00:00.

You can pipe a collection of Hyper-V virtual machines or specify a virtual
machine name. Wildcards are supported. The default is to display last use data
for all virtual machines.

You can run this on a Hyper-V server or from any domain member that has the
Hyper-V management tools installed, such as a Windows 8 computer. The command
uses PowerShell remoting to retrieve the disk information.
.Parameter Name
The name of a Hyper-V virtual machine or a VM object. You can pipe Get-VM
to this command.
.Parameter Computername
The name of the server to query. The default is the local host. If you pipe
a Get-VM command that queries a remote computer, the computer name will
automatically be used.
.Example
PS C:\> Get-vmlastuse xp*

VMName             CreationTime               LastUse                    LastUseAge
------             ------------               -------                    ----------
XP Lab             3/3/2013 1:05:29 PM        7/14/2013 9:07:19 AM       33.00:57:04.8442216

Get last use information for any virtual machine starting with XP.
.Example
PS C>\> get-vmlastuse ubuntu* -computer HV01

VMName             CreationTime               LastUse                    LastUseAge
------             ------------               -------                    ----------
Ubuntu 12 x86      3/3/2013 3:31:55 PM        6/25/2013 8:26:00 AM       52.01:47:42.9022213

Get the Ubuntu VM from server HV01.
.Example
PS C:\> get-vm -computer HV01 | where {$_.state -eq 'off'} | get-vmlastuse

VMName             CreationTime               LastUse                    LastUseAge
------             ------------               -------                    ----------
10961A-LON-CL1     3/15/2013 6:08:54 AM       8/13/2013 5:06:02 PM       2.17:02:13.8564362
10961A-LON-DC1     3/15/2013 6:08:09 AM       8/13/2013 3:22:44 PM       2.18:45:32.0323689
10961A-LON-SVR1    3/15/2013 6:09:32 AM       8/13/2013 3:21:36 PM       2.18:46:40.0599579
CHI-APP01          6/5/2013 12:49:28 PM       8/16/2013 8:48:54 AM       01:19:21.9799246
CHI-Client02       3/3/2013 3:31:42 PM        8/3/2013 7:48:14 PM        12.14:20:02.4111888
CHI-DEV01          5/29/2013 4:18:21 PM       8/16/2013 9:32:30 AM       00:35:46.8916567
...

Get last use information for any virtual machine that is currently off on a remote
Hyper-V server.
.Example
PS C:\> get-vmlastuse -computer HV01 | Sort LastUseAge | Out-Gridview -title "Last Use Report"

Get last use information for all virtual machines on server HV01, sorted by age.
All results will be displayed with Out-Gridview.
.Notes
version 2.0
Brought to you by Altaro http://altaro.com/hyper-v

New to PowerShell? Try "Learn PowerShell 3 in a Month of Lunches"

****************************************************************
* DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
* THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
* YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
* DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
****************************************************************

.Inputs
String or Hyper-V Virtual Machine
.Outputs
Custom object
.Link
Get-VM
Get-Item
#>

    [cmdletbinding()]
    Param (
        [Parameter(Position = 0,
            HelpMessage = "Enter a Hyper-V virtual machine name",
            ValueFromPipeline, ValueFromPipelinebyPropertyName)]
        [ValidateNotNullorEmpty()]
        [alias("vm")]
        [object]$Name = "*",
        [Parameter(ValueFromPipelinebyPropertyname)]
        [alias("cn")]
        [string]$Computername
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

        #define a hashtable of parameters to splat to Get-VM
        $vmParams = @{
            ErrorAction = "Stop"
        }
        #if computername is not the local host add it to the parameter set
        if ($Computername -AND ($Computername -ne $env:COMPUTERNAME)) {
            Write-Verbose "Searching on $computername"
            $vmParams.Add("Computername", $Computername)
            #create a PSSession for Invoke-Command
            Try {
                Write-Verbose "Creating temporary PSSession"
                $tmpSession = New-PSSession -ComputerName $Computername -ErrorAction Stop
            }
            Catch {
                Throw "Failed to create temporary PSSession to $computername."
            }
        }
    } #begin

    Process {
        if ($name -is [string]) {
            Write-Verbose -Message "Getting virtual machine(s)"
            $vmParams.Add("Name", $name)
            Try {
                $vms = Get-VM @vmParams
            }
            Catch {
                Write-Warning "Failed to find a VM or VMs with a name like $name"
                #bail out
                Return
            }
        }
        elseif ($name -is [Microsoft.HyperV.PowerShell.VirtualMachine] ) {
            #otherwise we'll assume $Name is a virtual machine object
            Write-Verbose "Found one or more virtual machines matching the name"
            $vms = $name
        }
        else {
            #invalid object type
            Write-Error "The input object was invalid."
            #bail out
            return
        }
        foreach ($vm in $vms) {

            #if VM is on a remote machine using PowerShell remoting to get the information
            Write-Verbose "Processing $($vm.name)"
            $sb = {
                param([string]$Path, [string]$vmname)
                Try {
                    $diskfile = Get-Item -Path $Path -ErrorAction Stop
                    $diskFile | Select-Object @{Name = "LastUse"; Expression = {$diskFile.LastWriteTime}},
                    @{Name = "LastUseAge"; Expression = {(Get-Date) - $diskFile.LastWriteTime}}
                }
                Catch {
                    Write-Warning "$($vmname): Could not find $path."
                }
            } #end scriptblock

            #get first drive file
            $diskpath = $vm.HardDrives[0].Path

            #only proceed if a hard drive path was found
            if ($diskpath) {
                $icmParam = @{
                    ScriptBlock  = $sb
                    ArgumentList = @($diskpath, $vm.name)
                }
                Write-Verbose "Getting details for $(($icmParam.ArgumentList)[0])"
                if ($vmParams.computername) {
                    $icmParam.Add("Session", $tmpSession)
                }

                $details = Invoke-Command @icmParam
                #write a custom object to the pipeline
                $objHash = [ordered]@{
                    VMName       = $vm.name
                    CreationTime = $vm.CreationTime
                    LastUse      = $details.LastUse
                    LastUseAge   = $details.LastUseAge
                }

                #if VM is running set the LastUseAge to 0:00:00
                if ($vm.state -eq 'running') {
                    $objHash.LastUseAge = New-TimeSpan -hours 0
                }

                #write the object to the pipeline
                New-Object -TypeName PSObject -Property $objHash

            } #if $diskpath
            Else {
                Write-Warning "$($vm.name): No hard drives defined."
            }
        }#foreach
    } #process

    End {
        #remove temp PSSession if found
        if ($tmpSession) {
            Write-Verbose "Removing temporary PSSession"
            $tmpSession | Remove-PSSession
        }

        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end

} #end function

Function New-HyperVHealthReport {

    <#
.Synopsis
Create an HTML Hyper-V health report.
.Description
This command will create an HTML-based Hyper-V health report. It is designed
to report on Hyper-V 3.0 servers or even Client Hyper-V on Windows 8. This
script requires the Hyper-V, Storage and NetAdapter modules. It can be run on
the Hyper-V server use PowerShell remoting or you can specify a remote computer
for the report with the -Computername parameter. But the machine you are running
from must have the required modules.

Another option is to use PowerShell remoting and run the script on the remote
computer. See examples.

The report only shows virtual machine information for any virtual machine that is
not powered off. If you include performance counters, you will only get data on
counters with a value other than 0. Data from resource metering will only be
available for running virtual machines with resource metering enabled.

If you don't specify a file name, the command will create a file in your Documents
folder called HyperV-Health.htm.

.Parameter Computername
The name of the Hyper-V server. You must have rights to administer the server.
.Parameter RecentCreated
The number of days to check for recently created virtual machines.
.Parameter Hours
The number of hours to check for recent event log entries. The default is 24.
.Parameter LastUsed
The number of days to check for last used virtual machines. The default is 30.
.Parameter Performance
Specify if you do want performance counters in the report.
.Parameter Path
.Parameter Metering
Specify if you do want to include resource metering in the report.
The path and filename for the HTML report.
.Example
PS C:\> New-HVHealthReport -computer HV01

Create a report for server HV01 with default values. The report will be saved locally
in the documents folder as HyperV-Health.htm
.Example
PS C:\> New-HVHealthReport -computer HV01 -performance -metering

Create a report for server HV01 with default values including performance and
resource meter data. The report will be saved locally in the documents folder
as HyperV-Health.htm.

.Link
Get-VM
Get-VHD
Measure-VM
Get-CimInstance
Get-Counter
Get-Eventlog
.Inputs
This command does not accept pipelined input.
.Outputs
an HTML file
.Notes
Version 0.9.5

****************************************************************
* DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
* THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
* YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
* DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
****************************************************************
#>

    [cmdletbinding()]

    Param(
        [Parameter(Position = 0, HelpMessage = "The name of the Hyper-V server. You must have rights to administer the server.")]
        [ValidateNotNullorEmpty()]
        [String]$Computername = $env:computername,
        [Parameter(HelpMessage = "The path and filename for the HTML report.")]
        [ValidateNotNullorEmpty()]
        [ValidateScript( {
                if (Test-Path (Split-Path $_)) {
                    $True
                }
                else {
                    Throw "Can't validate part of the path $_"
                }
            })]
        [String]$Path = (
            Join-path -path ([environment]::GetFolderPath("mydocuments")) -child "HyperV-Health.htm"
        ),
        [Parameter(HelpMessage = "The number of days to check for recently created virtual machines.")]
        [ValidateScript( {$_ -ge 0})]
        [int]$RecentCreated = 30,
        [Parameter(HelpMessage = "The number of days to check for last used virtual machines.")]
        [ValidateScript( {$_ -ge 0})]
        [int]$LastUsed = 30,
        [Parameter(HelpMessage = "The number of hours to check for recent event log entries.")]
        [ValidateScript( {$_ -ge 0})]
        [int]$Hours = 24,
        [Parameter(HelpMessage = "Specify if you do want performance counters in the report.")]
        [switch]$Performance,
        [Parameter(HelpMessage = "Specify if you do want resource metering in the report.")]
        [switch]$Metering

    )

    #region initialize
    $reportversion = "0.9.5"

    Import-Module Hyper-V, Storage, NetAdapter

    #parameters for Write-Progress
    $progParam = @{
        Activity        = "Hyper-V Health Report: $($computername.ToUpper())"
        Status          = "initializing"
        PercentComplete = 0
    }

    Write-Progress @progParam

    #initialize a variable for HTML fragments
    $fragments = @()
    $fragments += "<a href='javascript:toggleAll();' title='Click to toggle all sections'>+/-</a>"

    #endregion

    #region get server information

    $progParam.Status = "Getting VM Host"
    $progParam.currentOperation = $computername
    Write-Progress @progParam

    $vmhost = Get-VMHost -ComputerName $computername |
        Select-Object @{Name = "Name"; Expression = {$_.name.toUpper()}},
    @{Name = "Domain"; Expression = {$_.FullyQualifiedDomainName}},
    @{Name = "MemGB"; Expression = {$_.MemoryCapacity / 1GB -as [int]}},
    @{Name = "Max Migrations"; Expression = {$_.MaximumStorageMigrations}},
    @{Name = "Numa Spanning"; Expression = {$_.NumaSpanningEnabled}},
    @{Name = "IoV"; Expression = {$_.IoVSupport}},
    @{Name = "VHD Path"; Expression = {$_.VirtualHardDiskPath}},
    @{Name = "VM Path"; Expression = {$_.VirtualMachinePath}}

    $Text = "VM Host"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"
    $fragments += $vmhost | ConvertTo-Html -Fragment
    $fragments += "</div>"

    $progParam.Status = "Getting Server information"
    $progParam.currentOperation = "Operating System"
    Write-Progress @progParam

    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computername
    $osdetail = $os |
        Select-Object @{Name = "OS"; Expression = {$_.caption}},
    @{Name = "ServicePack"; Expression = {$_.CSDVersion}},
    LastBootUptime,
    @{Name = "Uptime"; Expression = {(Get-Date) - $_.LastBootUpTime}}

    $Text = "Operating System"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"
    $fragments += $osdetail | Convertto-html -Fragment
    $fragments += "</div>"
    $progparam.PercentComplete = 5
    $progParam.currentOperation = "Computer System"
    Write-Progress @progParam

    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $computername |
        Select-Object Manufacturer, Model, @{Name = "TotalMemoryGB"; Expression = {[int]($_.TotalPhysicalMemory / 1GB)}},
    NumberOfProcessors, NumberOfLogicalProcessors

    $Text = "Computer System"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"
    $fragments += $cs | ConvertTo-HTML -Fragment
    $fragments += "</div>"
    #endregion

    #region memory

    $text = "Memory"
    $fragments += "<a href='javascript:toggleDiv(""$Text"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$Text"">"

    $mem = $os |
        Select-Object @{Name = "FreeGB"; Expression = {[math]::Round(($_.FreePhysicalMemory / 1MB), 2)}},
    @{Name = "TotalGB"; Expression = {[math]::Round(($_.TotalVisibleMemorySize / 1MB), 2)}},
    @{Name = "Percent Free"; Expression = {[math]::Round(($_.FreePhysicalMemory / $_.TotalVisibleMemorySize) * 100, 2)}},
    @{Name = "FreeVirtualGB"; Expression = {[math]::Round(($_.FreeVirtualMemory / 1MB), 2)}},
    @{Name = "TotalVirtualGB"; Expression = {[math]::Round(($_.TotalVirtualMemorySize / 1MB), 2)}}

    [xml]$html = $mem | ConvertTo-Html -fragment

    #check each row, skipping the TH header row
    for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
        $class = $html.CreateAttribute("class")
        #check the value of the percent free MB column and assign a class to the row
        if (($html.table.tr[$i].td[2] -as [double]) -le 10) {
            $class.value = "memalert"
            [void]$html.table.tr[$i].ChildNodes[2].Attributes.Append($class)
        }
        elseif (($html.table.tr[$i].td[2] -as [double]) -le 20) {
            $class.value = "memwarn"
            [void]$html.table.tr[$i].ChildNodes[2].Attributes.Append($class)
        }
    }

    $fragments += $html.innerXML
    $fragments += "</div>"
    #endregion

    #region network adapters
    $progParam.currentOperation = "Network Adapters"
    $progparam.PercentComplete = 10
    Write-Progress @progParam

    $Text = "Network Adapters"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"

    $fragments += Get-NetAdapterStatistics -CimSession $computername |
        Select-Object Name,
    @{Name = "RcvdUnicastMB"; Expression = {[math]::Round(($_.ReceivedUnicastBytes / 1MB), 2)}},
    @{Name = "SentUnicastMB"; Expression = {[math]::Round(($_.SentUnicastBytes / 1MB), 2)}},
    ReceivedUnicastPackets, SentUnicastPackets,
    ReceivedDiscardedPackets, OutboundDiscardedPackets | ConvertTo-HTML -Fragment

    $fragments += "</div>"
    #endregion

    #region check disk space

    $progParam.Status = "Getting Server Details"
    $progParam.currentOperation = "checking volumes"
    $progparam.PercentComplete = 15
    Write-Progress @progParam

    $vols = Get-Volume -CimSession $computername |
        Where-Object drivetype -eq 'fixed' | Sort-Object DriveLetter |
        Select-Object @{Name = "Drive"; Expression = {
            if ($_.DriveLetter) { $_.driveletter} else {"none"}
        }
    }, Path, HealthStatus,
    @{Name = "SizeGB"; Expression = {[math]::Round(($_.Size / 1gb), 2)}},
    @{Name = "FreeGB"; Expression = {[math]::Round(($_.SizeRemaining / 1gb), 4)}},
    @{Name = "PercentFree"; Expression = {[math]::Round((($_.SizeRemaining / $_.Size) * 100), 2)}}

    $Text = "Volumes"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"

    [xml]$html = $vols | ConvertTo-Html -Fragment

    <#
I don't know why, but I can't add attributes to two different nodes
at the same time so we have to go through all the volumes once to
look at health and then a second time to look at percent free space.
#>

    #check each row, skipping the TH header row
    #add alert class if volume is not healthy
    for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
        $class = $html.CreateAttribute("class")

        if ($html.table.tr[$i].td[2] -ne "Healthy") {
            $class.value = "alert"
            [void]$html.table.tr[$i].ChildNodes[2].Attributes.Append($class)
        }
        else {
            $class.value = "green"
            [void]$html.table.tr[$i].ChildNodes[2].Attributes.Append($class)
        }

    }
    #go through rows again and add class depending on % free space
    for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
        $class = $html.CreateAttribute("class")

        if (($html.table.tr[$i].td[-1] -as [double]) -le 10) {
            $class.value = "memalert"
            [void]$html.table.tr[$i].ChildNodes[5].Attributes.Append($class)
        }
        elseif (($html.table.tr[$i].td[-1] -as [double]) -le 20) {
            $class.value = "memwarn"
            [void]$html.table.tr[$i].ChildNodes[5].Attributes.Append($class)
        }
    } #for

    $fragments += $html.innerXML
    $fragments += "</div>"
    #endregion

    #region check services

    $progParam.currentOperation = "Checking Hyper-V Services"
    $progparam.PercentComplete = 20
    Write-Progress @progParam

    $services = Get-CimInstance win32_service -filter "name like 'vmi%' or name ='vmms'" -ComputerName $computername |
        Select-Object Name, Displayname, StartMode, State, Startname

    $Text = "Services"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"

    [xml]$html = $services | ConvertTo-HTML -Fragment
    #find stopped services and add Alert style
    for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
        $class = $html.CreateAttribute("class")
        #check the value of the State column and assign a class to the row
        if ($html.table.tr[$i].td[3] -eq 'running') {
            $class.value = "green"
            [void]$html.table.tr[$i].Attributes.Append($class)
        }
    }
    #add the revised html to the fragment
    $fragments += $html.InnerXml
    $fragments += "</div>"

    #endregion

    #region enum VM
    $progParam.Status = "Getting Virtual Machine information"
    $progParam.currentOperation = "Enumerating VMs"
    $progparam.PercentComplete = 25
    Write-Progress @progParam

    $Text = "Virtual Machines"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"
    Try {
        #get all VMs that are not turned off
        $allVMs = Get-VM -ComputerName $computername -ErrorAction Stop
        $runningVMs = $allVMS | Where-Object State -ne 'off'
        $vmGroup = $runningVMs | Sort-Object State, Name | Group-Object -Property State | Sort-Object Count

        #define a set of properties to display for each VM
        $vmProps = "Name", "Uptime", "Status", "CPUUsage", "MemoryAssigned",
        "MemoryDemand", "MemoryStatus", "MemoryStartup", "MemoryMiniumum",
        "MemoryMaximum", "DynamicMemoryEnabled"

        foreach ($item in $vmGroup) {

            [xml]$html = $item.Group | Select-Object $vmProps | ConvertTo-HTML -Fragment

            $caption = $html.CreateElement("caption")
            [void]$html.table.AppendChild($caption)
            $html.table.caption = $item.Name

            for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
                $class = $html.CreateAttribute("class")
                #check the value of the MemoryStatus column and assign a class to the row
                if ($html.table.tr[$i].td[6] -eq "Low") {
                    $class.value = "memalert"
                    [void]$html.table.tr[$i].ChildNodes[6].Attributes.Append($class)
                }
                elseif ($html.table.tr[$i].td[6] -eq "Warning") {
                    $class.value = "memwarn"
                    [void]$html.table.tr[$i].ChildNodes[6].Attributes.Append($class)
                }

            } #for

            $fragments += $html.InnerXml
        } #foreach
    } #try
    Catch {
        $fragments += "<p style='color:red;'>No virtual machines detected</p>"
    }

    #region created in the last 30 days
    $progParam.currentOperation = "Virtual Machines Created in last $RecentCreated Days"
    $progparam.PercentComplete = 28
    Write-Progress @progParam

    if ($allVMs) {
        $recent = $allVMS | Where-Object CreationTime -ge (Get-Date).AddDays(-$RecentCreated) |
            Select-Object Name, CreationTime, Notes
        if ($recent) {
            [xml]$html = $recent | ConvertTo-HTML -Fragment
            $caption = $html.CreateElement("caption")
            [void]$html.table.AppendChild($caption)
            $html.table.caption = "Created in last $RecentCreated days"
            $fragments += $html.InnerXml
        }
        else {
            $fragments += "<table><caption>Created in last $RecentCreated days</caption><tr><td style='color:green'>No virtual machines created recently</td></tr></table>"
        }
    }
    else {
        $fragments += "<p style='color:red;'>No virtual machines detected</p>"
    }

    #endregion

    #region last use
    $progParam.currentOperation = "Virtual Machines not used within last $LastUsed Days"
    $progparam.PercentComplete = 30
    Write-Progress @progParam
    $last = New-Timespan -Days $LastUsed
    $data = Get-VMLastUse -Computername $Computername | Where-Object {$_.lastuseage -gt $last } | Sort-Object LastUseAge

    if ($data) {
        [xml]$html = $data | ConvertTo-HTML -Fragment
        $caption = $html.CreateElement("caption")
        [void]$html.table.AppendChild($caption)
        $html.table.caption = "Not used in last $lastused days"
        $fragments += $html.InnerXml

    }
    else {
        $fragments += "<table><caption>Not used in last $lastused days</caption><tr><td style='color:green'>No unused virtual machines detected for the last $lastused days.</td></tr></table>"
    }
    #endregion

    #region Integrated Services Version
    $progParam.currentOperation = "Integrated Services Version"
    $progparam.PercentComplete = 35
    Write-Progress @progParam

    if ($runningVMs) {
        $isv = $runningVMS | Sort-Object IntegrationServicesVersion | Select-Object Name, IntegrationServicesVersion

        [xml]$html = $isv | ConvertTo-HTML -Fragment
        $caption = $html.CreateElement("caption")
        [void]$html.table.AppendChild($caption)
        $html.table.caption = "Integration Services Version"
        $fragments += $html.InnerXml
    }
    else {
        $fragments += "<p style='color:red;'>No virtual machines detected</p>"
    }
    #endregion

    #endregion

    #region VHD Utilization
    $progParam.currentOperation = "Analyzing Virtual Disks"
    $progparam.PercentComplete = 40
    Write-Progress @progParam

    $fragments += "<h3>Virtual Disk Detail</h3>"

    if ($runningVMs) {
        $progParam.Status = "Getting Virtual Disk Detail"
        foreach ($vm in $runningVMs) {
            $progParam.currentOperation = $vm.name
            Write-Progress @progParam
            #get VHD details
            $vhdDetail = foreach ($drive in $vm.harddrives) {
                Try {
                    $detail = Get-VHD -ComputerName $computername -path $drive.path -ErrorAction Stop
                    $vhdHash = [ordered]@{
                        ControllerType     = $drive.ControllerType
                        ControllerNumber   = $drive.ControllerNumber
                        ControllerLocation = $drive.ControllerLocation
                        VHDFormat          = $detail.VHDFormat
                        VHDType            = $detail.VHDType
                        FileSizeMB         = [math]::Round(($detail.FileSize / 1MB), 2)
                        SizeMB             = [math]::Round(($detail.Size / 1MB), 2)
                        MinSizeMB          = [math]::Round(($detail.MinimumSize / 1MB), 2)
                        FragPercent        = $detail.FragmentationPercentage
                        Path               = $drive.path
                    }
                    New-Object -TypeName PSObject -Property $vhdhash
                } #try
                Catch {
                    $fragments += "<p style='color:red'>$($_.Exception.Message)</p>"
                }
            } #foreach drive
            if ($vhdDetail) {
                [xml]$html = $vhdDetail | ConvertTo-HTML -Fragment
                $caption = $html.CreateElement("caption")
                [void]$html.table.AppendChild($caption)
                $html.table.caption = $vm.Name
                $fragments += $html.InnerXml
            }
        } #foreach vm
    }
    else {
        $fragments += "<p style='color:red;'>No virtual disk files found</p>"
    }

    #endregion

    #region Resource Metering
    if ($Metering) {
        $progParam.currentOperation = "Gathering Resource Metering Data"
        $progparam.PercentComplete = 43
        Write-Progress @progParam

        #region Resource Pool
        $fragments += "<h3>Resource Pool Metering</h3>"
        #turn off error handling. There might be some resource pool data for some
        #types
        $data = Measure-VMResourcePool -name * -computer $computername -ErrorAction SilentlyContinue |
            Select-Object ResourcePoolname, AvgCPU, AvgRam, MinRam, MaxRam, TotalDisk,
        @{Name         = "NetworkInbound(M)";
            Expression = { ($_.NetworkMeteredTrafficReport |
                        Where-Object direction -Eq 'inbound' | Measure-Object TotalTraffic -sum).Sum
            }
        }, MeteringDuration

        if ($data) {
            $fragments += $data | ConvertTo-Html -Fragment
        }
        else {
            $fragments += "<p style='color:red;'>No VM Resource Pool data found</p>"
        }
        #endregion

        #region VM metering

        $fragments += "<h3>VM Resource Metering</h3>"

        if ($runningVMs) {
            $data = $runningVMs | Where-Object {$_.ResourceMeteringEnabled} |
                ForEach-Object {
                Measure-VM -name $_.vmname -ComputerName $computername |
                    Select-Object VMName, AvgCPU, AvgRAM, MinRam, MaxRam, TotalDisk,
                @{Name         = "NetworkInbound(M)";
                    Expression = { ($_.NetworkMeteredTrafficReport |
                                Where-Object direction -Eq 'inbound' | Measure-Object TotalTraffic -sum).Sum
                    }
                },
                @{Name         = "NetworkOutbound(M)";
                    Expression = { ($_.NetworkMeteredTrafficReport |
                                Where-Object direction -Eq 'outbound' | Measure-Object TotalTraffic -sum).Sum
                    }
                }, MeteringDuration
            } #foreach
            $fragments += $data | ConvertTo-Html -Fragment
        }
        else {
            $fragments += "<p style='color:red;'>No virtual machines detected</p>"
        }

        #endregion
    }
    $fragments += "</div>"
    #endregion

    #region check for recent event log errors and warnings

    $progParam.currentOperation = "Checking System Event Log"
    $progparam.PercentComplete = 60
    Write-Progress @progParam

    #hashtable of parameters for Get-Eventlog
    $logParam = @{
        Computername = $Computername
        LogName      = "System"
        EntryType    = "Error", "Warning"
        After        = (Get-Date).AddHours(-$Hours)
    }
    $sysLog = Get-EventLog @logparam
    <#
only get errors and warnings from these sources
 vmicheartbeat
 vmickvpexchange
 vmicrdv
 vmicshutdown
 vmictimesync
 vmicvss
#>
    $progParam.currentOperation = "Checking Application Event log"
    $progparam.PercentComplete = 65
    Write-Progress @progParam

    $logParam.logName = "Application"

    $appLog = Get-EventLog @logparam -Source vmic*

    $Text = "Event Logs"
    $div = $Text.Replace(" ", "_")
    $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"

    $fragments += "<h3>System</h3>"

    if ($syslog) {
        $syslog | Group-Object -Property Source |
            Sort-Object Count -Descending | ForEach-Object {

            [xml]$html = $_.Group | Sort-Object TimeWritten -Descending |
                Select-Object TimeWritten, EntryType, InstanceID, Message |
                ConvertTo-Html -Fragment

            $caption = $html.CreateElement("caption")
            [void]$html.table.AppendChild($caption)
            $html.table.caption = $_.Name

            #find errors and add Alert style
            for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
                $class = $html.CreateAttribute("class")
                #check the value of the entry type column and assign a class to the row
                if ($html.table.tr[$i].td[1] -eq 'error') {
                    $class.value = "alert"
                    [void]$html.table.tr[$i].Attributes.Append($class)
                }
            } #for
            #add the revised html to the fragment
            $fragments += $html.InnerXml
        } #foreach
    } #if System entries
    else {
        $fragments += "<table></caption><tr><td style='color:green'>No relevant system errors or warnings found.</td></tr></table>"
    }
    $fragments += "<h3>Application</h3>"
    if ($applog) {
        $applog | Group-Object -Property Source |
            Sort-Object Count -Descending | ForEach-Object {
            $fragments += "<h4>$($_.Name)</h4>"
            [xml]$html = $_.Group | Sort-Object TimeWritten -Descending |
                Select-Object TimeWritten, EntryType, InstanceID, Message |
                ConvertTo-Html -Fragment

            $caption = $html.CreateElement("caption")
            [void]$html.table.AppendChild($caption)
            $html.table.caption = $_.Name

            #find errors and add Alert style
            for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
                $class = $html.CreateAttribute("class")
                #check the value of the entry type column and assign a class to the row
                if ($html.table.tr[$i].td[1] -eq 'error') {
                    $class.value = "alert"
                    [void]$html.table.tr[$i].Attributes.Append($class)
                }
            } #for
            #add the revised html to the fragment
            $fragments += $html.InnerXml
        } #foreach
    } #if
    else {
        $fragments += "<table></caption><tr><td style='color:green'>No relevant application errors or warnings found.</td></tr></table>"
    }

    #region check operational logs
    $progParam.currentOperation = "Checking operational event logs"
    $progparam.PercentComplete = 68
    Write-Progress @progParam

    $fragments += "<h3>Operational logs</h3>"

    #define a hash table of parameters to splat to Get-WinEvent
    $paramHash = @{
        ErrorAction   = "Stop"
        ErrorVariable = "MyErr"
        Computername  = $Computername
    }

    $start = (Get-Date).AddHours(-$hours)

    #construct a hash table for the -FilterHashTable parameter in Get-WinEvent
    $filter = @{
        Logname   = "Microsoft-Windows-Hyper-V*"
        Level     = 2, 3
        StartTime = $start
    }

    #add it to the parameter hash table
    $paramHash.Add("FilterHashTable", $filter)

    #search logs for errors and warnings
    Try {
        #add a property for each entry that translates the SID into
        #the account name
        #hash table of parameters for Get-WSManInstance
        $script:newHash = @{
            ResourceURI   = "wmicimv2/win32_SID"
            SelectorSet   = $null
            Computername  = $Computername
            ErrorAction   = "Stop"
            ErrorVariable = "myErr"
        }
        $oplogs = Get-WinEvent @paramHash  |
            Add-Member -MemberType ScriptProperty -Name Username -Value {
            Try {
                #resolve the SID
                $script:newHash.SelectorSet = @{SID = "$($this.userID)"}
                $resolved = Get-WSManInstance @script:newhash
            }
            Catch {
                Write-Warning $myerr.ErrorRecord
            }
            if ($resolved.accountname) {
                #write the resolved name to the pipeline
                "$($Resolved.ReferencedDomainName)\$($Resolved.Accountname)"
            }
            else {
                #re-use the SID
                $this.userID
            }
        } -PassThru

    }
    Catch {
        Write-Warning $MyErr.errorRecord
    }

    if ($oplogs) {
        $oplogs | Group-Object -Property Logname |
            Sort-Object Count -Descending | ForEach-Object {
            [xml]$html = $_.Group | Sort-Object TimeCreated -Descending |
                Select-Object TimeCreated, @{Name = "EntryType"; Expression = {$_.levelDisplayname}},
            ID, Username, Message |
                ConvertTo-Html -Fragment

            $caption = $html.CreateElement("caption")
            [void]$html.table.AppendChild($caption)
            $html.table.caption = $_.Name

            #find errors and add Alert style
            for ($i = 1; $i -le $html.table.tr.count - 1; $i++) {
                $class = $html.CreateAttribute("class")
                #check the value of the entry type column and assign a class to the row
                if ($html.table.tr[$i].td[1] -eq 'error') {
                    $class.value = "alert"
                    [void]$html.table.tr[$i].Attributes.Append($class)
                }
            } #for
            #add the revised html to the fragment
            $fragments += $html.InnerXml
        } #foreach

    }
    else {
        $fragments += "<table></caption><tr><td style='color:green'>No relevant application errors or warnings found.</td></tr></table>"
    }
    $fragments += "</div>"
    #endregion

    #endregion

    #region get performance data
    if ($Performance) {
        $progParam.status = "Gathering Performance Data"
        $progparam.PercentComplete = 70
        $progParam.currentOperation = "..System"
        Write-Progress @progParam

        $Text = "Performance"
        $div = $Text.Replace(" ", "_")
        $fragments += "<a href='javascript:toggleDiv(""$div"");' title='click to collapse or expand this section'><h2>$Text</h2></a><div id=""$div"">"

        #system
        $ctrs = "\System\Processes", "\System\Threads", "\System\Processor Queue Length"
        $sysCounters = Get-Counter -counter $ctrs -computername $Computername

        [xml]$html = $sysCounters | Select-Object -expand CounterSamples |
            Select-Object Path, @{Name = "Value"; Expression = {$_.CookedValue}} |
            ConvertTo-HTML -Fragment

        $caption = $html.CreateElement("caption")
        [void]$html.table.AppendChild($caption)
        $html.table.caption = "System"
        $fragments += $html.InnerXml

        #memory
        $progParam.currentOperation = "..Memory"
        $progparam.PercentComplete = 72
        Write-Progress @progParam

        $ctrs = "\Memory\Page Faults/sec",
        "\Memory\% Committed Bytes In Use",
        "\Memory\Available MBytes"
        $memCounters = Get-Counter -counter $ctrs -computername $Computername

        [xml]$html = $memCounters | Select-Object -expand CounterSamples |
            Select-Object Path, @{Name = "Value"; Expression = {$_.CookedValue}} |
            ConvertTo-HTML -Fragment

        $caption = $html.CreateElement("caption")
        [void]$html.table.AppendChild($caption)
        $html.table.caption = "Memory"
        $fragments += $html.InnerXml

        #cpu
        $progParam.currentOperation = "..Processor"
        $progparam.PercentComplete = 75
        Write-Progress @progParam

        $ctrs = "\Processor(*)\% Processor Time"
        $procCounters = Get-Counter -counter $ctrs -computername $Computername

        [xml]$html = $procCounters | Select-Object -expand CounterSamples |
            Select-Object Path, @{Name = "Value"; Expression = {$_.CookedValue}} |
            ConvertTo-HTML -Fragment

        $caption = $html.CreateElement("caption")
        [void]$html.table.AppendChild($caption)
        $html.table.caption = "Processor"
        $fragments += $html.InnerXml

        #physicaldisk
        $progParam.currentOperation = "..PhysicalDisk"
        $progparam.PercentComplete = 77
        Write-Progress @progParam

        $ctrs = "\PhysicalDisk(*)\Current Disk Queue Length",
        "\PhysicalDisk(*)\Avg. Disk Queue Length",
        "\PhysicalDisk(*)\Avg. Disk Read Queue Length",
        "\PhysicalDisk(*)\Avg. Disk Write Queue Length",
        "\PhysicalDisk(*)\% Disk Time",
        "\PhysicalDisk(*)\% Disk Read Time",
        "\PhysicalDisk(*)\% Disk Write Time"

        Try {
            $diskCounters = Get-Counter -counter $ctrs -computername $Computername -ErrorAction Stop
            $data = $diskCounters | Select-Object -ExpandProperty CounterSamples |
                Where-Object CookedValue -gt 0
        }
        Catch {
            $fragments += "<table><caption>$($counterset.CounterSetName)</caption><tr><td style='color:red'>$($_.Exception.Message)</td></tr></table>"
        }

        if ($data) {
            #non zero data found
            [xml]$html = $data |
                Select-Object Path, @{Name = "Value"; Expression = {$_.CookedValue}} |
                ConvertTo-HTML -Fragment

            $caption = $html.CreateElement("caption")
            [void]$html.table.AppendChild($caption)
            $html.table.caption = "Physical Disk"
            $fragments += $html.InnerXml
        }
        else {
            $fragments += "<table><caption>$($counterset.CounterSetName)</caption><tr><td style='color:green'>No non-zero values for this counter set.</td></tr></table>"
        }
        #Hyper-V Perf counters
        $progParam.status = "Getting Hyper-V Performance Counters"
        $progparam.PercentComplete = 80
        Write-Progress @progParam

        $hvCounters = Get-Counter -ListSet Hyper-V* -ComputerName $computername

        $data = foreach ($counterset in $hvcounters) {
            $progParam.currentOperation = $counterset.countersetname
            Write-Progress @progParam

            #create reports for any counter with a value greater than 0
            try {
                $data = Get-Counter -Counter $counterset.counter -Computername $computername -ErrorAction Stop |
                    Select-Object -ExpandProperty CounterSamples |
                    Where-Object CookedValue -gt 0 |
                    Sort-Object Path | Select-Object Path, @{Name = "Value"; Expression = {$_.CookedValue}}
                if ($data) {
                    [xml]$html = $data  | ConvertTo-HTML -Fragment
                    $caption = $html.CreateElement("caption")
                    [void]$html.table.AppendChild($caption)
                    $html.table.caption = $counterset.CounterSetName
                    $fragments += $html.InnerXml
                }
                else {
                    $fragments += "<table><caption>$($counterset.CounterSetName)</caption><tr><td style='color:green'>No non-zero values for this counter set.</td></tr></table>"
                }
            } #try
            Catch {
                $fragments += "<table><caption>$($counterset.CounterSetName)</caption><tr><td style='color:red'>$($_.Exception.Message)</td></tr></table>"
            }
        }
        $fragments += "</div>"
    } #if not $NoPerformance

    #endregion

    #region create HTML report
    $progParam.status = "Creating HTML Report"
    $progParam.currentOperation = $Path
    $progParam.percentcomplete = 90
    Write-Progress @progParam

    $title = "$($os.CSName) Hyper-V Health Report"
    $head = @"
<Title>$($Title)</Title>
<style>
h2
{
width:95%;
background-color:#7BA7C7;
font-family:Tahoma;
font-size:12pt;
font-color:Black;
}
caption
{
background-color:#A9A9F5;
text-align:left;
font-weight:bold;
}
body
{
 background-color:#FFFFFF;
 font-family:Tahoma;
 font-size:9pt;
}
td, th
{
 border:1px solid black;
 border-collapse:collapse;
}
th
{
 color:black;
 background-color:#F2F5A9;
}
table, tr, td, th
{
padding: 3px;
margin: 0px;
border-spacing:0;
}
table
{
width:95%;
margin-left:5px;
margin-bottom:20px;
}
tr:nth-child(odd) {background-color: lightgray}
.alert {color:red}
.green {color:green}
.memalert {background-color: red}
.memwarn {background-color: yellow}
a:link { color: black ; text-decoration: underline}
a:visited { color: black ; text-decoration: underline}
a:hover {color:yellow}
</style>
<script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js'>
</script>
<script type='text/javascript'>
function toggleDiv(divId) {
   `$("#"+divId).toggle();
}
function toggleAll() {
    var divs = document.getElementsByTagName('div');
    for (var i = 0; i < divs.length; i++) {
        var div = divs[i];
        `$("#"+div.id).toggle();
    }
}
</script>
<br>
<img src=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHsAAAB9CAIAAAAN/Is1AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAD0SSURBVHja7L13mBzVlTZ+zg1VnaZ7kmakkVBOKIAACYExGZEsMEvyGj6SzZrFZs3+HHDCNmvvOuxicHoevPY+xuAPg41NBhNFEEEICaGcGEmj0Ugzo0nd06mq7j3n98cdtYeREGlky99ynoGn1V3VU/XWuSe+5w4yM3wo71UcZvh+TlUH/OIsAAIIArDAQASMGgRIDgAFgAYGRiAABgiBBRiAUBmrhABAYGuFYNRofEYQAhCBwVoqC0ESGCD9N0Ac94D+Pk490DrOAGAJiUFKQDAIEQABKI6YSEpUwAghhAXIZzmbLRe2lXN9UbaHSnmgkISVMeXFY4kxH9HpESIzEmI1BnwJgGTBEitv4E4Q/y6WxwFHPIJQWJSsASBkMECgSAIDak1Fkd0VdrXk2jeavp1+mJdBkOjq4qBIpZwMCxT0R+X+KCpZpoKpNpkGnDSn+qhT0zOOxfToEDQA+MzuFhARESuvDzBuxFagPEgRL2nwgUVkgZB8GQDnINtjWt/Mbttc3rFZFNtjOkpU+56ngyCI5SIISxAWIchDuR9KBSgWOQptyZSN2FUQnVgjpx094sSP1R93st8wwSPtbkEIAQDM7KA/sHjbSAj9/uz4X8GqlBE8SyIA8EUkTWd29Utbli4+ZPMSz5bTSQEZDQkfqjLWSweh8Irt1oRUynOQV6WyLAWiWMbQdFsw/WUZAFvVkqWtHK+Ze+Lhpy+sW3gNEQGAlNIhXkH/APomE0rpHaSIAxCTMYJ0kaKEh9C9+7++GN/0SHUmxolkmKw1yWpZlfG9OFpjg5Is93NYxkIBygUolyHIm6Bkw7AU+eUil0JZNlAIwlLIpRIWizRp4SUTrrg2fthHAiYAk0APrCnJIF4JChiJWAgFLAGAEQAYkQEIQAAIYACGkEFLACAAg4DAGtwhEgAJgACAGXHAlBBFQuiDIFapPL/KumZGiwQgQGoGNj3ttrdTaQSpUCghxIA1AAtsgZmImEgQoSUgA+SErY0iQmvBGLbWEgGBIIQH/+9dTRy78gdHxT0/YuQQOEQvlSQyBIgghQCUwADEQERaCdjzLwBCUIACAKQICCSAEuARAxAICSAIWAALZiJmISQzIALA+zTif43oEBlIEIIAlAxBacta6N3m+wBKg9RCahRKAgoGIgJrwEUgZIEMkmFLYIkIrLXEEBFZRkvstI4RxtSlU0oLkGQDwwWBMeUlohC0VgBABMzACAyAglAQMzNYF0MhIoNFEIAgwLcWmEEoQCSQEUFIELJJae0jqj26TYiCiASKgwjxtzguRAaBVlgETUFp0/JE0K3TEqQEqUApKaUQgpkFkWULxMAW2SITsCUiskAWAMGtH6eZBsAgGoC+QvbwKVMhNJQob9rxCoXhrLFHS7+BrQRmiYgoAGjPqQwg96mfaEEBgDIAEZEFlAKTAqpYBwzELNgCCnAOApEBDw4d32eQgIDIwgrwSn12y+oqHQL4ID2QGqVCpRARmYCsIIvEbBnIAkdAhsEyMzNGli2BdbaAwRJGhiKDanRj1Zixbb1dMT//h8d/vn7d66fMPefshVeNS09VKgEQtxEwCaUBUACFIHBw8sIMzAAIAs1A+sC+YOFeWwtWZwWkJCZQAdNfjCc6U3kw5pxknC0VAnjXm7qzRccEIQqhSUgQCoVARCBntS0QMxlwP+yMOJAFa8FaMJatEYGF0HBgRNlQasoRUD9CZmRXblt774Z+0/nY83e8sW3ZpWd/ZvzYGeNGzBG6GhnYOqVkBmZGYBiwyAgoLCKDUQN+UgCJYpE7dnSu2bZ9w6plLccd87GjZp/mK20okkBS+IhIbAR6ByXiQAKUACQo9axf7ud7oA5BxVkqkAqERJSICJbIWDQWiJDYkkUyYCOwA6AzgSEgi5EFIrSExNKSrJs8nzKZdNpb+sqyXG+PRNC+6S+9ecvvvnjYzHkfmXfG9PFHj0iNT6gaBTEEyVBElABCgABwNt0QGKN0xLkAevoKW1q73tjeuWpL64qtrc1vLqqbPXMuSEOglVJRWJCejyjx/ab5Bx5xiQOrzxZ7WjaPigIjhFI+SAFCghAscCDIsURkkYiJkBmZiHlAxwkQB4IEAMHAIASiEEo0TTlKxuIW8ls3rUmIZCnKZ6rjBoteE2/oXrz96SUja8ZNHXP0oWOPG103Jx1rSnmeEJ5ABYBENjKlyJStDbaWF3f3N/cW13UV1u3OtRbLJiAtMjJT442bNEahCMIo7kml1J48g/EgRJyZMVLsBWXl+zvb4tteSFYVCt6YmEgojKH2rO+hRogsmhCsYQJhChQV0JTREEVsWRrkMlgALABQBEDUb2yMoJSzPGuOGje+JjOup/Bca9/iXF+Hr1KByLEHCQLlg/KjHLy5smPLhr7747GqmBdvqJ4RiyV8PyYECiCGIIz6y0Eh8Fv6ww4Rx4K1gbUA6IWp7s25qSPnj6ufumtHm1YJVVvteR8UsQOv4wIZfATIbd8ggxwpLaWvEAABULpKCBGhdapNwMxMLqxjFwYzEGCpzMYASmmj0ANgC6FUY6ZOTaUSsTiu37qtN5sjIqWAGUAMrAkhUEqWCoRkFBGg3NW71PdisVhCax3zlecD6AhFGcEqLQ0ZZrYhUMQcYbHf1o4etbNtd67PjBo5TkpNxEIAEb3P/Of9edt3mQQNvBBAAJLLhfWvJMKc9eJCxAABULBAEAjETJZNxNaQjdhGbO0e881kwTCQZUPADCQxsuwRRCGV48mGmbNiKV/q4qbmNblsnhGEJBYg1QDiKEEpIT0UmlAYxnIsKb24kB5Lj9GzoC0rAzpitFIiGybD1gIZCPI2zMP0qUcV+g2TTCaqXCD7AStlYvjNyKCrYWbrllKpy25ZlsKy9ROMGphBaZTKHYyW0BqkCCgEa9AYtuRicQIkKwwJkAAWwogtoSJRDEA0NCbGTfRiWAh3bt+xMbQgFIA0UgoUTsGFkCAkux8UhjEi9gl8Rg+ETxgz7IVWlEJkiJjZWmsilgzCqP4uk/ZHHjJ6KlmZSqVjsZjzKAcX4vuoHRJLAOh4U/dskUKw8hARpGatQWlEicRoDZJFcoEKuQxoT+7DxECAEQNEGESWlAoi7rdQPWmaahhTlY7t7Nqwc/cWJgAEUFZ5GgCEQhaMyCwYgBAZpEvciyCKQgZCh9qPUJfRK6MXAJBlIkKKQIHmQPd1hOMaD0/G66OIk8mk9qQ1/MERG2bEhyg4MyOyCovlza/FghzouJRaSAK/CpRmKRjBqTMQIRm0IZAVxGwJCZxORRaNhZDQnUBKFUIua69h2qE6VZdIes3bXu/NdYQREIKQRijJAoQEKQElICIIZAREKVD5Gj0FKAjQWhsYG4QmNBSQYCYkq9hINjIocpBT08fP19oDgHhcCwHaQ/GBy8AHXMeVICjvzq57LSaZdEoJicKASrISgMLVrcAaYDvwQ4atGahfERhiazmyTIzKABCWiEoIuq6+YfJ0L1YdmMLG5uVh1G8YtAYQzGylRiFYSHCVMgSJoAVqlDGFcYUxT8QVxgTGgDWSRog5t2ECQlJhiYJ+9kT11HFHGGM8TyVTMQDjMqiDHXFgC0G2uHNLTHvkxaWQKCygz4CMwIzWWiYCYiAml3MyAzs7DkRs2VWyyIbGhFEpjFirVH199chRMT/Z3dfVtmsLCpACtY8owFqrlHI1EDlQnZSIAlEKoZgMg0GwAiyTYRsaWzZR2RhjLRtDzCIq26BsEn51Q+3Ycrkcj/vxmAaw1g5DZXvYEDcDvVYC5wA5EsKiMP3Cx7WL0v3bQEspbEkkiqoBvG6hUbBVQdkPA2FCsASE2mowIAEJOAAwEkgCIxGQtKlcPEE+xsuUDdk/6oRidWN9bWZz1+/yhUIxB/GYAKmsAFZGsUUFiIwMElCikFIIhaxISC1QAypEgcgorMRQiqKFsrGodCKXK2lZ3b4tPnvKGYgyjArpdDVAHMBHZFcx/CBNhWGLx/eUwwUAAzIgMLCxkBBQam3TZQLfR1ZxjoUiDRD1x5QkAGRkFIBIIQWFKMrHCv2SSUUcM4IjLhsZGQqIolLBWEFABoBVbOzEKYlEAkW0ZdvWfD7vUCBmrVF5LKVEpAGTgoiIlRfutZCAiFQJQhmJIAxDilApKPQGJsKJE6ZKKZVSnjdQP6m0lj5IrDKMiDMCVholDGCYLAJmm7u2rRwBeYgr8CPQkZCmjDYdJoEJwtAWylAgLLMIZZxirHJEGFouE5WsCELmSGmDLKOQmC2GwLp25KixE72YyuXbt2x5sxgUtS9BMoMVApQSjIQSUIIQA6bciUIhhEQphBBON5gtMxsi1/ExAWv2u3uilD96/LhJJozi8XgikagEvkT0AVt6w2ZV0DUJEFAKRrAAgEJLbbo3R327Yqk4aDQcAlildSyTAS6BLYEtCyJGsigixjIxhsChiYhKGsoehZoMExtCRGMotJy3onHqbFVdn8rEdnVt6OjexWA8TyklhQKQCAIILUpEhSgFSBDyL2oOAge8KRgCw0wWmBmtQQRtAgOh199lJh8yOxmrKQfFZDIZj8eHsTc5fDqODIBEMGDpDCklAKi4caXO5yGWMsZHzweRBKMhioEfQUhBEEUKsCotU1VhUFUulmIiDaUs5nd7UQgGLHFZQKiBi8wAkYUcqZmz5kReLJn0Nra8nM/3GyItrZAstEBlUaPWEiSBECwYUaD7DxFRAgtEJARw5cqBIJbDgE1oyYAtYr4HZsyfj9YDCFOpVIWU8QEt+IHpczq6EjsuEJtyMdz4dMJ0gMpYP66SGcOitbM7tyvY0S9RalA+YwyEEkICZIAslFsSJc4EUBeVYlHkh1E+CEzIJgQSKgTAdH31pEO5qiqE7Lptr5TDEiEwMiMJKQZ6yRJQIoiBF4goUApAiUIIwYgAZNkwWEACAEvALGxAHsa7+422NYeMnBkG4Ps6mUy+Y8vlb4W4ABAD18OkJAKHuc5W27utqi4RxjJr896OXd1ljqvacXWNU/Sso1JVNanqGhVLMAoiAmJmC8GuUkd7b8uWrpat2Nmqoi6l+uMy7CmFpYhKIYycPtUf2ZRoqN/Rt7S9b2NoI6VBSkRXx5UAAlCwECAVDjjPPWZcCIFKC4EAlpkMGyKyTNZaJsXMbCjXFYxtmlObHkklkcrEKyZloCBx8CDOzHtK2ABsAQ2YMNe9u31nsS+IcooL4+Y0Hjaz5pBpkD4EQASetdaWiYGFUFIrAdZYEyk1w586w5txkg27ox2bSmteDtcts7taEvF0Lt8fkp04fqJIVOlkvHnlpt5Ce2TA90EpYaWVUiiFWqPUAJIYseIzK4GKlFIIgIFmHsMAWYDDwDBjUI76+uCIWdMSfqZYMolETAhhjKmQYQ4ixJEtk7QSBPQC+cAJgFhqzAx7+hVhvKm2elpDalQg/H4GBsmobWCFkAzCAtgII5TJZDIR9xrjWdRevhwEQT2lDsExR+TnbGpe/7pd/ji0lUy/TUyfmqyu09GmHTueyoWhtT7qWEiB9jRIAGQUHhnhYb9CAiYEEIgoXMGWBAOitoIiCkPOExmygkwcqGxD5jBd6itOGjc/DI32qLq6mpkrXYhhoXoNn1URjOzCxBgKtFFBxlS6vua4C/+/ns58ew/1lEShDOVIWZMwoe7ul8ZCObDlki2GbCJLGACG9VWF+jqaMD41bXKyvomgNCJsPKRxzLH9o6c1L1+CpWjUlBMi47OFju0dtpd8L1BgkYxCcAwfhMjz9+SaUg554Um2tki2DBhqBdayQQLi0DBZb/fO8tiGQw9pnGRDIwASqeTwlz2Gr51JjGwMSRU3VCJZZEiUIZmzsfWdyc3NXbmCsSz9RDzmJwR5Ji7KIZUtB560iJGAcgBRYFs7MrwhsM90JfzNxx6ZPuOUiWObqlNNpeSY8zOzjyl1l/KQbqrzdnStbevcHpVA+KCE9WLK06iEFYo8BVIYAIUggHHwD4JQIJilABAAEdkgiMJAGKsMgsRE147c0eNm1sYaggImM1VSKuCDFnH0GCJfeUDAIKRObOmwazcUXl6ZzfeHSsarq0dUZZSKSeGLsBxG5bIJmUIEoyV7kgAtsYmkgmIAITd1d9S8+Ye2x/68+MTjqy48b079yHhNOiF2tZe6C1U15eXLnmnra6M4pFMAEoxlxYqFQm0tWCbwhcBBdrxizS34hJFhbUCwVKDIIpcNMUAUWEWp6ePmQBnI2OpMVUSo8aBFHCQiAVAQMAORTN5z37LXVniZETOVxExGCMXAZWAW1kMrFCQtgkUmQLLAFpAZADwIy1RiIwCFUHU7O+Cu33Y9/uirn/rM1NNPrhkxZlRNfWhMUZtqDlLWBBFEMV95cRWJ0JBNSK1iGjUKwc6SSCkHv4hURGiJo9CWQluIiCMLkYUqrbe29SfU2AnjptjIeFJX19aAEDDcvMxhyzmtBSaX6kexeDzbDxvf9EOYatF6MRH3wZfoC+WhFhbQQpEgIAgYSwBF4BKYEkSRMLmCQRv3yNNhKExeSlm0tZtaq77wuWd//KNFDEkVy8RE0yWnffmG//OTqfXHmLIu59ka9DwRSwDqyHLZQmlImf4vyYsqGciFJku2rABioD1K6CjVtVEWd8bGN86oy4wITaTiGhEjaw9eOy4VAQgilMISwOq1YU/Oj9XFhNerPIlCSoSYp7UAYxwBBRiAyVXFka0iI20k/KQo9oelIGQQwDIKrRS+FBCVMhz4YUglm63yExKrTpz/yZFNR/7+0Vs2Nr/ev7O1pkkkkzEUZeQo6SeZUQglhJJSS6ndCyGUBBBW+JxKqCobcdeuoP3NUtcuYzrqxtRNnzvrNJSJSERV1RkhUYMcdh0fRqsSWSsECu2pkGzzll2GPUDw/Iz0BAoCZaVGBrYWAT1lQ2sIDSgriRUzukp4d84zNipj0cioZG1khCBNxbyndhx71AItQ+NFu/NrM8aLp6aOGTvns//n1jfWPr9szUPrtz3Tmt1R0whVdR4p7WeEK/tprbXWnud5nqeUwsijAuT6crs7unduy2d3QkZPnlQ/+9h/WDiyfnQmNaLQb0DIeCppB/hD8iBF3IAvJWAZwOvNmZEvrY9DrKZahppRA8U0xDUKoSxDxBQxG+sZ4ghsIERkMWQoWQ4NSCQql3XBh0hLkTUiiqy0gkaO8KCup6NP1ia2LL7vS/m+3vnHXTjjyGuSVaOPm3PO5HFHbWu/dEvr8uaWJZ2b1+ZsLyfZT9hETRCrslKHkSkGRQwDoM5sVBYS6qQ9fGbDYTPPnF9XM7qqKsOyWOquzXWrWDyoH1lbk4kbLilM4MHjOYe27V1NRRMI3doWFPqNVKi1ktKKPVXTCu+PiIklDzBSgIiJ2HV2rbXWWkRBjGFgmBQbW+rvnXHs6JE1I6tjiZ1bNvZ1tHR3tD2d+9WqFatOO+Of60ZMGj96TEPt6PFNcw+bfl5vdnuh1JXdub5QzvXmdhd35xgo6SfqY1W+jlfNmlyTbKirakqK+pQXV1gul7sh31NQ2aaRE6pS9fEkKe0DaiTLDCgOVjuOQMgSZMDgr12XK5VkvEZKiUqyJ6VWKCUCDNAH7QDErndMRNJaJiIyTESGrGuBhgEjaTYhmb5pMxpjwsRFeefWFVjOVikI+9u76YkH7l43Y+bx02edUdN45PiR48c11PRkp/flsjj2lCgKSmEQ2RCBlWsvM1io8VSIYZ+2u2XQFpY2lIvby6XejZ0jF551WE0mhh5FrCIDWnlwAOZHhrMjAQDAURnTazd2A9ZpxQIcLQWUQqlgoJxBwhEiXGGaB3TctZQZXaOT2Bhi0mAkheWaGp55VDyeiAD7ens3hEEeWaR8LWTZo+atG3e0bf9zzYgJh4w/qqlpbl16St2YEUakLMXCwAuC0ERlNiU2ebKhjDaBbcuXVwvaHkVbybTHmLM9ha2bDkv+g0VNDIDoelkCDIA+mBFnsMjtfdC83Uo/qaXRSijJSrLSA6EtETAiMDABE1pGZmBCNkQEbMFay8yRMcZaIVQQmLDcNXOGl27AWFJk+9f35N4sW5AMvkwCR74kJUoaSqZvV+vqJTvWplOJhurqJp0e53sJ7aUlSA9IcElAEWzJRBuk6kl5vQLC/qAQWDBRur/DGzduXKKuLiqVijbyE7XCNRLxINZxMiwECIxt2lruyXmJGlSKtKe0NFIJJUEIIMtkgQksgGEgQGYkYnbmxTAbCgNDBMYYZkYQYVAA6p8+bURVVdWI2rrm9Wvy/Z0oQGoEGQGSEKAlxkjELCaU8HReQVYUNpcLCPGMiKVBaq3A1xTTIUoD3A+2QAYwqiqFaBjykerNQdPM2YXecHtbT6o2XudnpJDGhkp6w474sPkFIRRYIPBXru4MMak88BQoSUoLLVBKEAhEFNGeCQhnwS0zoaOm2IGRKjKRJSIDJjIhmSiRoFkzR1THlOZy6+alUSGPkfI9QizHPGEAUGghY8AekEQr3VNMxjkRM3G/HIuXY7GyFyujKhBnQcUBNRgZRIDCNwJ6iuVsxBxrenN7X18uyFRVJzypB1hEB5OODyldCiEgtKzklm27pd+gNCglAUhKFGLPPD0zM5AFGjDoaNkS4cAMEDMRAAgisMBEFIYhAGXS3rjxtTGZNfli966NMcCykcCGKdJCgRQWyGIBNYgYsJKg48pLeiR0FAPUyEr6UgICB4KLUZSTKiIfIlsMDfSHIpvPsGisHTmZbDwel8lElTWhVEII5ANgV4ZBxx0dGSxEsXB9G+3eMSajPaWyDAp1oMjGY0IIKAc2JGZAa8lGwITWAoBiEiayxhi21phQllBYjIwIA6MIbNHMOnRS/ehS3YiRzW2PhGGuUGSV8iJW2gMVkY/WB/KEVAKZAJGViEAUyCsZVQAd6JiVOgQugO0HKik0wFgOISxLDlBzbFd3vmb09JQYHQTdqQxJrQAlgELw4QAMu4r3BfG+qg1kAXjjpp6SQRkTWsdiHsRVTEopxVueDTtvycCErpFOg8QYYw0IkMTGWguYnTxNay+QGHZ3txaLRSGQIUBBEhGRKl3jwa0eCQMdskELkQaVgJgIpBIRcakM2T47cvRkIpJSOqLEEPbk3x5xRLmP6+DQAK5YnY1ETCcAQWsJPihP456RG2RCR94cFImTtWytHaDREjBYY4gss7EU2erqcMbhnq8ijjp3tW3I5/ul1AyhQBJCoQCFINygEToyitjDexuYzh0YT2YGtgDkbJe1YDkMifIFVY4yo0bNtNZqrdPpNLx1xP/g8JwM+7Bv0vbmaWsLykSahZEgFJInQMuB1gwQghVM0hAQVNIf3gP6wA+ANYbYMFhlSnbi+MzoJqqKJfp7N/d2b4siEEIoCVoCMgjtPAQ70AVChZcihJBiD2/CEdnZAhggBpaGoBgRgbe7V1TXzlCJJmOM53lDOvdwALaxEO/Xbe5dPNSbmotdWV/FgMHENfiSpAIlEQGI3FoemDLZY1j+MlhVsSqWImuttUyRjILizBkNcc/Wp2t3t60ISj1CACAqCUoCM0vpJpEBkREZEVHwICPjQGcAQleWIstgTSSYIbJgwd/VQU2HHGlkmpnj8fhfYZOW92fH91nJ0qvWhhElhQbJ5GuQSrC0WrIAN/TqRmQHQkOXDZEFR122lqxlshCGITKQjWxIyUT50BlVMYm+T+2tr1NYUmqAGaERJBJIEAhSkMABTZcoEFEOWBUY4GEBMFsEy2CJbBQSkUIBhZLI5v0RTdMNKillKpU6EIZ7WOz4Pt7sLtsNG4xOJDwFCRXz0SglUJMQKBCAKursgj8HtytjUSUSt9ZagwBgbWiiYPQ4GD+Zq1Iq37uhu3MjhQGilBIVADIoJYDlHmYhSOEGDv/SYHNju4gMSIDEzOBmcq1i61mrurtLVZkxqczIEMD3fYf4gd4W531ZlX1dya7dPW1tked7WkFMCyGMUqATSu6h/w6Mse2pFzLD4BDF6T4RA0tEtKZsbTjmEK++0STior1zdbnQY0LLjCAFMwKAVAgoEZ1JQUcEckBXBAAEomAXXxGzJQYhpCGMQu7NBg0NYz0/GZrA87x4PA4HXt5/dOjoqAxkuMwiWLe+GoVJAcQRUOasZPYBZShSItIQ+RZT1ksZP24SPlRpMJ61viDAMEJjGMGCKFjoLoNfLBcUJK3decQxY8tlUV2t2ltXFcJIedr32JOBkiwAJEcSwhiAxyiRQSC6qXOFQgAIFgolCiACtgKIwFiwxoCJikyFIoitfbGa8ScaTMYxX11dbQf12NwuOQfCyKj3ZVUkAAjhqoVCiTgDr9y8NVTajwOBScTitQmtIyh25jraKNffm811R1GAiEw6DDgoG103XslYzM8k2LOEYdlSGNegAmspCqP+0ugmf8I4ry6FXMi1b18bRRGR0cKpLUgJSgkthRD0F5pbRc2FGojNBTuLtmd9gSVkFoaoUFBC1FSlm4BjiFEsFhtMD6+YlGG3LR+kkmUqe/B0dvRvb5N+si4eBwqDnZs71rbstEEuliw31WFtbXrKoTXpTK1U6Kw2EbTssi2tm9u35CxXebFGD+uCwC9miZk89AvFXROP9EePimrSKte9Lbd7s4kCKdw0PSGikrCn0QGVuFsI6eBGRKU8IRxF3NkT19QDG+mIjSHd2U3p9JR01SGh0dqPJxIJRw8/0NtsfRDE2dhQyZi1sKN1d74t1l/avX39SoE7Zk/MnHzcyOmTJ9aPxIRf1FoKaY0tG1t2+QWCnEsCcGJ/QWzY1Lfk1R2bm1tMNCKTHLGrOxJhUmmcPqPO86JEUmxes9KaPDNJqZQEgSSBJQAyAwMioBhgGA4lqCACEINhiJitq8Uzg7FkQLXvDhsnz0aVtKGpTqWGl+p2oKq1e7YBA621V1w8a+yoSYfWTpk6d9wID6ICip0Bd0dRdVhmaw0AuSYvgI1MFNOd5cAm/PjRc0ceeeTcHTt48eLmJa88K9WMnnZbk7HTZzdKWZbKbGl7LYgigaAlSolC2IEBWQQ5MNKy5/+IbicLRBQgAQgoBAiQzQBRzwpCGzIUI8wW40eOPbxoQhQ6na4FAGttxbAcuHDlgyCOQii3S8nESaPv/J9P5MvFzt6dxWJnqS9Qwktm0kqOiqVrtNa+72vtSyndwgcWvigR2ZCjIDTlKKyp0U1No044IX7XfbmV/Z2HjC2NHCETOt6f29Tbt8laFADIJFEIBCXAWRgpUQjeU5t0saAzChJAgKvAs0E0zJYtWAOWyRJ09UEsMSlTN76vVK6qklXJpItNB0+cuCzfGFNR/7854qpSokpVSQxgd09fFIaj6kfXZdJaeqDjrNEbiA7/EsUzMAAIkxAaFEIiQcaGiNhUryeN8Q+ZOH7FsTviXqGpJmqqz+zYtqaUb4UgED4ICciEiFqiECQApDPfg4ZO3mJVeGAbNzfs41JZa4Ql2dnJjaOOBFEDysTjcS3igG/ZFq+i3cML9wdC3FoWEgHIUIDILOTIQ0Y2QpNWqICAgREjABzYHswtfCQO3eZ3rGKWLBIIZIkKUUjtx1KxTG12dCZTyHJP5/YqPWPn9tW2nFMEzpIAgARGFLgn9RX74hcOTM0iuk2e3AYBZNkatkYAJHp6ytMnTA2NLz3p+3FkDTiQ+xy8dtz15gGEFnEAAA3CWgASLAAFAwOzh8jMQmAUGSk1EQnhMTMCMrNEATi4OMagpaTq2mpRnRlZVVMfYg5UXXsulUzlM1qhRKkFSwpspDQqT1lkVgYFSSEkoAYlEZRk7ZNlC8iCAC0CS2IZARUBPR017wxITa4+ZCLpCAgXPf1sdnevjOv58+fPnTvXGXQp5UFoVfbdFRqiI26C2M0YVDKL/UVgGCpPA6vqTL3S8WOPudBD+fLih8rBGiGk9KSnQDIIZgXsSykEolAoPBSShGRQljUaFdOSjbGmICAPEhiUVUgKtu5SW3aCSjRVpxtLIFPx2Lhx49pYLl3x2sSJE6Mo8jzPXa0QIooirYe5mT+ce3oOXpJDtpp0WvO2gf1gPeI+YoWYjAwCkaciEKWNr7/y0rM/yua2KbGzoT6qS1NckCalwPN81Ap8H2Oe8LXSvqf9pFKe1BGZHEBRSC4b1dFlm1tLuzrsjt5MKnPY+EkLJ04/LVuyY8eOralO24hCE2QyGafabgzlAAXm+Lfd8b0ykDroabG1JUQPhQKGUtEm4rKYLe1oWdG2442Wlmd7u17T3NZYgyPrq6pisYxX0pp9TZ5H2kOtfCE9EF4gZRTZXH/Qtivf0hru7k2AHBuLj26YMW/0yJlVqYm9WSbmqdMmVldXO6AdcaOybc0+tOH/AcTf+ZEwIIK1UAwK+Wx3f0977+6t7a3LezpXhOUWhmxjuqQ1+76NeawkEmNkwVrc2e3n86ZY1n5sbN2IWfWjDq+pn5ZMjgjjIiwBGG1CW1ebGTt+tNbakEUGrbXb63I/kTgzR1HEzO7ggwXx3t7ejRs3TpgwobGxcXjsFXAIAYEM8qa3s7fQ18WmNwo7+/s7Onu2RmExLPebqAxsUQoUWqCqrh6fStZWVY9MpEYwJg0oQA1ClSKLhNXJqqpUorqmKpmMAxAKhW9dc/uUTZs23XvvvcuXLy8UCpdddtmll176PsyOGrzAX3jhhW3btgHARz/60cmTJ7+LANE+9thj3d3dyWTy5JNPrq+vB4ByufyNb3zjtttuO+ecc+64446ampphWImAyFKj8FJ+JtVUKtb254rZbD/Giqkmi8RI1g1vAoBhY5kkCle+CoAZUAgBSMzhhJGHVKWTsZinlEJkADCGlCC3M8tgRa5sgODkueeeu/rqq5ubm10QWVtbe/7557tO9PtEPIqiH/7wh48//jgAXHHFFbfddts71otffvnliy66KAiCmpqaBx988Pjjj3cK/sorrwDASy+91NXVNSyIA4BHmhgQiUXgJzCeSNc0ZILA9ud2RIGJSqEJDVkCJCUYwYaktSelFlKBp2NVyaqqRCbmxdBEoJDIAHJorJRaSslgrSGlVCXcGgJ3T0/PV77ylebm5qOPPvrzn/98qVSqqamp2HfnAN6tua90CYIgOPvss92b8Xj81Vdf5XeSf/zHf3TH19XVLV68eE+3gX73u9+ddNJJP/7xj4Mg4GESInKq517s4QFYZg7D0H1UKpWKxWIulyuVSkEQhGHoPnKnON9YOTEIAve++5L9yz333BOLxTzPq9ymk/b29htvvPGyyy5rbm5+lzfyFsQXLlxYcRpf+tKXHPnv7WT58uV1dXUVxF988cXKR8aYbDbr7nYYEXfX4xyXe22Mcf+sAFcBd/DDds/JQVz5nsGf7v9OmfkHP/gBAEyfPr1cLg9+//777weASZMmrV69+l3eiBgSq3meN23atHg8/tvf/ratrW0/i+M3v/lNd3f3hAkTUqlUpWOyJx2V6XR6eHMHN+BdKXS4127HmYFu1lt3IhxsFpy58DyvMij+FsM6KEHbf3K3d7Pf/XPwrjcVJEulUhRF75xzhmE4b968VCq1bNmyu++++ytf+crbee3HHnsMAM4999zbbrttCLjlcrlYLMbj8X16gp6enq6urkKhIIRIp9OjRo2KxWLuKvP5PDMnk0mlVKlUamlpkVKOGzdu8P0UCoWOjo58Pm+MSSQSDQ0NtbW1+7zIQqHQ1taWz+eVUjU1NaNGjdrb1BaLxfb29v7+fiJKJBIjRowY/G3MXCwWk8lkqVRyrq6/v19rXQG6UCi4Ky8UCsaYfD6fSqWiKHrkkUeam5sbGxsXLlw4YsSIt7XjH/vYxwDg3//932+66Sa3iPr7+/e5NL773e8CwIknnvjwww8PsSpRFN12223HHnvs3nZ8x44dt95664IFC1xUI4SYOHHipz/96fb2dmZ+8803P/WpT51++umbNm1avXr1eeedV1tb29TU9Nprr7nTi8Xi73//+wsvvPCQQw5x91xTU3Pqqaf+/Oc/z2azQ67wscceu+CCC9zdep43c+bMn/zkJ4MPCMPw7rvvvvjii8eOHevWR319/YIFC2677bbe3l53TLlc/ta3vnX22WcfeuihAJBOpxcuXHjWWWddfvnlV1111cc//nFXh0kkEieffPI//MM/nHHGGffff//69etvuumm888//9/+7d+eeOKJIX5i34i3traOHj0aAH71q1/tDff27dvnzZsHAH/4wx9efvnlIYgHQfCZz3wGAC655JJCoVA5a/Xq1SeffLJ7zKNGjTrppJPmzZvn+77W+qWXXmLmJUuWjBkzBgB+8YtfHHnkkRUD8uijjzJzLpe77rrrnLJnMpmPfOQjxx13XEUfP/7xj7vH5uSuu+6qrq4GgNra2pNPPnn27NkAcMQRR1QO6Onpufrqq91jS6fTxxxzzPHHH19xS5dccsnu3buZOZ/Pn3HGGXuvnlGjRjU1Ne1zYf3gBz9Yvnz5r3/96yuuuOLOO+985JFHhvizfSB+ww03MPNll10GAMcff3zFNVXkl7/8JQBMnjy5u7v72WefHYJ4GIaf+9znAODKK68slUoV7XaxY319/U9/+tPNmzfv3r17165dr7zyyg033PDGG28w87Jly8aNG+cc0ZgxY/74xz+uW7fu8ccf37Fjh7X2G9/4hrulf/3Xf129enVHR0dHR8fmzZu/+tWv+r4PAP/0T//kfld3d7dTyXPPPXfz5s1dXV07dux45JFHfvazn1U85L/8y7+4J/qlL31p3bp17e3tnZ2d69at+9rXvuYe8/XXX++Q2rRp0/r166+77joAmDp16pIlS5YtW7Zy5crVq1evWLHi5ptvBoBx48b96U9/Wrt27ZIlS3bv3t3W1vbDH/7w5ptvvummm9ytvQPiX/ziF5n5ueee01pXVVU98MADg0/o6upasGCBWwrM/OSTT74bxJ2ZSiQSDz300JArCMPQPdRly5aNHz/eHfbMM88MiYtcrvGlL31p72Duy1/+slPnF154gZlffPHF+vp6rfVTTz01JCZxkczTTz/tzNrXvva1SmxTCXic60okEkuXLq28/8Mf/hAA5syZM8ROPvLIIwBw6KGHbt68eXBY1d7evmrVqpaWlr2v9m0z2hNPPPG0007r7+//05/+NPj9pUuXPvXUU42Njeeff/5gXsd+pK2t7cEHHwSAz372s5WQvyJa6yEO7bzzzjvllFMGv/Pggw8Wi8XZs2d/5jOf2TsL//znPz969Oienh7nzF2PIoqiTZs2DYlJnBl57LHHurq6JkyY8IUvfGHvuYPLL798ypQpxWJx0aJFQ+gre1dEwjB01a7BYQkiNjY2zp49u+Ih3i1D6JprrgGARYsWuRzSefbbb78dAC666KLp06e/y8CupaVlxYoViPixj33sHeMwAHBraLBvf/XVVwHgyCOPnDJlyt7HjxkzxvmVdevWAcDhhx/ujOy3v/3tX/7yl93d3UOCk/Xr17vfUjHcg2XSpElHHHEEALz++usO0L8eJ+vUU0+dP39+W1ubC0gAYO3atffee291dfX555//7os4O3bscHcyatSod3P8EKdkjHHVnrFjx77dKc4BdHV15fP5RCLxne98Z/To0V1dXf/8z/98xhln3HzzzZ2dnZXY1D2DKVOm7PMWfN93T6K7u/vdrODhRDyVSrmo4/7779+8eTMAOJ952mmnnXDCCe+lI2pd+vAuc6IhRsZl5Ptv8rpvHpiPATj33HP/9Kc/XXrppYlEYvny5V/+8pcXLlz40ksvOTvgNHc/F7OHjntA6tjvUOE9/fTTZ8+evWHDhhdeeGHnzp333HNPPB6/8MIL341xGIJgR0dHLpd7l22Kt9SwPM9FgV1dXW93ys6dO10g5IYcAGD+/Pm33377s88+e/nll2utX3vttWuvvbanp6eurs4Fjh0dHW/3bS6vqa6uPhB/ke8dvnHMmDGf+MQnAOChhx762c9+ls/nDz/88HPOOec9/Y6xY8d6ntfZ2bl69er3c4lCuIB69erVvb29ex9QKpXWrFnjorchij9v3rw77rjjRz/6kVJqw4YNjz/+eCaTcVX7F1980e5r+5TW1tYNGzY4tzEkd9/PFb77Z/POxy1cuHDcuHGPPvroz3/+c8/z3FJ9T5BNmjTpox/9qDNK7e3t76jUe4sLW1988cWHHnpo70/vueeeNWvWpNNp53JdFDj4gE9+8pOjRo2Kosh5lNNOO01KuXjx4nvvvXfvb1u0aNGrr74qhBgSL+1nOVprjTHDhrhTamttPp8fO3bsJZdc8l6VtL6+/qqrrkLEF1980eUvFeXavn37bbfd5pzEfuSss85asGCBMeZb3/rWXXfd5Va9M8oPPvjgt771LSI655xzXH746quv/vjHP25ubq6c/sQTT3R1dcVisRkzZgDAxRdf/JGPfMRlHn/84x+LxaI7LAiC++6775vf/CYAfOYznznqqKPe8dZc9b+1tfXFF1900Pf397/bjoSL/yuObrBccMEF9957b0dHx6WXXjqkbFQJVAf7GfemSy4qWrZx48bvfe97v//975cuXfrRj3501KhRfX19S5Ys2bRp05NPPjlt2rSh2yu91Yffcsstl1xyyerVq6+++uo777zz0EMPlVJu2rRp8eLF2Wx2wYIFrqDqnuKNN9545513zp07t76+vqOj4+GHHy6VSuecc85pp53m0vof/ehHV1xxxfr166+88srjjz/e5ajNzc1PPfVUqVQ65ZRTbrzxxsEmpXJHe6vjtGnTNm7c+N3vfvf111/P5/OnnXbaVVdd9W47Eueddx4AfP3rX9+7lnLJJZc0NDRs2bJlyPtPP/00ADQ2Nr7yyiuV1O76668HgKuvvrqSc7qq0K9//euZM2cOuYDzzz+/s7OTmd94442JEye6db3P8tnmzZuvvPJKV2isSENDw1e/+tVdu3ZVDlu5cqUry1QkkUhcc801bW1tg79tzZo1V1111ZDhtvr6+m9+85uDSzRObrnlFgA4+uij9+6xPPjgg4PD2R/84Af7r4+/ZdfhlpaWnp6epqamkSNHDsHFlTQnTZo0xEXk8/nm5mal1IQJEyr7dO/atWvnzp2NjY1jxowZEvN2dnauWrWqtbXV1VpnzJgxZcoUN4BTLpe3bt0ahuHkyZP3nvKr1IGbm5vXrFnjFm9jY+OsWbPGjRs3+KqIqLOzc+3atdu2bbPWVlVVzZo1a/r06XuHg0EQvPnmm2vXrs1ms0IIlyiOHj167zC0q6urtbU1lUpNnjx5yB25qufrr7+ezWYbGhoGV8T+LtkT/++J+BCCDxH/EPEP5UPEP0T8Q3kPooYUKMIwjMViro+1T3FEHKXUX2ffgAMh1lqXtTrSz/4PDoKgVCr5vo+IhULBWptKpRKJhKO+ONLze/rt0vXDXBn6lltu+Y//+I8gCFyBf5/y5JNPXnfdddu2bTvqqKOGJCN/L5LP52+88cZf/OIXbW1trvv6dlIsFr/+9a/feuutQoixY8f+6Ec/Wr58+erVq33fX7ly5YYNG6ZNm/ZeEReDn/yiRYuee+651157bT8nbNy48fnnn1+0aFGlHPF3J+l0uq2t7YknnvjZz362ZcuW/Ry5fPnyH//4xy+88EKhUBg5cmQmk5k5c2ZnZ+fPf/7zn/zkJ+vWrXsfq/wviCOi09n9Fx5dZbwyuvF3Kpdddlk8Hu/s7HSt0beT++67DwBmz57t2rOjR49uamo69thjlVKJRGLy5Mn2vW+XreB/pSxYsGDSpElr1qx5/PHHHTNib+nr63PF4Qq3+5xzznF2/4QTTjDGJJPJ99Gy+BvHKpU+2TAe+W4kmUyeddZZALBmzZrly5fv85hFixZt3bo1nU6feeaZ7p3a2tpUKpVKperq6hobG92fw/pr6/iqVauy2WxjY+M+G7XFYnH16tVENHXq1Lq6uvXr1/f09EyYMKGpqam7u/v5559ftWpVEARNTU3HHHPMYYcdts8Yqa2tbenSpWvWrMnn86NGjZo3b97cuXMHH5nNZjds2KC1njVrlrX25ZdfXrFiRV1d3cUXX/x2FTEAuPDCC2+99daWlpbnn39+n6Xw++67j5knTZo0hFswDFo2hM38qU99aj/Fxp/+9KduWbmS5hVXXAEAc+fO3bZt294H/8///A8AjBkzZt26ddbaY445BgBuvfXWN95447DDDht8GfF4/IYbbqgQ/gbXQufMmTP4SM/zrrrqqsGl10cffVRrPWbMmJUrV1aoqel0es2aNfu5kSAITjrpJABYuHChY5gOlq1btzp+wDe+8Q0eVtmHju+f6z8kIrzkkkvuuOOOZcuWLV261F3iYPnDH/4AAMcee+yhhx5aKBScWXj55Zf/+7//u6ur67rrrps0aVI2m33yySdffvnl//zP/3RzGpWy6u9+97trr702l8sdffTRZ599dnV19Zo1a+69997bb789m83efffdzqq64R1r7c033/zb3/52/vz506dPb29v3/+S9zzvoosueu6551599dWVK1e6rlBF/vznP7vy7AUXXDD8lnSIjp9++unPPPPMU0899fhb5Yknnli0aNFnP/vZwTre3d193HHHAcC11147hKG4dOnSESNGKKUcjy6fz8+fP98FRXPmzBmsgDt37rz88stdIPTkk0+6N1etWjVhwgQAuPLKK1tbWysH33777bFYTGv9m9/8pkJFc9YjkUh8/etf7+/vj6Kovb29WCzuX92am5td2+z73//+kI/OPfdcADjzzDN5uGUfiLvQJ74vSSQSTgEriFf6IxMnThzSIXK51Zw5c9xcQQXx6upqRxAc0t9x7aHrr7/eteu++tWvutN37tw55GBHwPv4xz8+BPGzzz77PQ1mFItFR2g95ZRTHJnWyWuvvebW669//ethR3wfBiSRSDQ1NQ1pXQ5ENkJ0d3fv3r178JunnnrqqFGjtmzZsnTpUqeVLq9zDblPfvKTQ/zhSSedtHemN3ny5JNPPtnRU8Mw7O/vf+655wDgE5/4xKhRo9z8jjtSaz1//vz77rtv27Ztu3fvdgxxN4t+3nnn7T074K528DA1IjY0NLityM4666zf/va3ixcv3rp1q6N/AsDixYtbWloaGxv3SWUezrqKk3PPPff222+31g4ZqnAp0q233uq4rBWZMWPGmWeeefvttz/88MPnnXeew3fx4sWrVq1KJpNOH4ccv89LcURGp9HZbNbxNF944YWOjo4K/4+ZY7GY472USqVsNusQJ6J0Oj1r1qy9I7yLL7548PBKFEWxWOyBBx5whnvevHkzZ85cu3bt448/PnfuXETMZrPPPPOMw6GhoeGvgbjv+0oppdQ+Y7W9B02UUmeeeeZvfvObhx9+uKOjw7EDn3766Vwud+WVV+7tTt+O7jL4fTf/4TzYn//8530eP2Q/X6WU65cO+c4JEya4v3ZVKR95nle5tcmTJ5966qlr16594IEHrr/++nQ6vXbt2hdeeMGFj8O+ucq+Ed9/53OfaciJJ544f/78JUuW/PnPf77mmmu2bNlSMSnvfv7K8a0c57iC5uc///l58+a5MZzBYoypra19x5no+fPnP/roo4O/0N3d4BNPO+20X/3qV6+//vobb7xxwgknPPvss/39/UcfffThhx9+wKu171saGxsXLFiwZMmS++6775prrlm+fPmqVauOPfZYRwseInvD58TxhMaPH++WV11dXXt7+/z5898HJ2nwitwPI9fJMcccc8QRR7z88ssPP/zwzJkz3ZJauHDhcI24H6gs/2Mf+1hjY+NLL720fv16N6py/vnnDx3zAgCAZcuW7f3mli1b3EjRcccdJ6XMZDKOa/jkk0++3RMaLhkxYoRLhZ544onnn3/+pZdeSqVS74YC9zdGfP78+W75/+QnP3nqqacaGhocAWpveeGFFxztf3Ch+Fe/+tWqVat833fhQU1NjUPh7rvvdpMfQ7oiK1asyGazw3Xxp59++ogRIzZs2OAi3ZNOOsk974PXqji5+OKLn3766TvuuKNcLl9xxRVD8vjB+H7xi1/s6+s788wzfd/v6en5wx/+4G71c5/7nKsEuGz2vvvuW758+bXXXtvS0nLKKafU1NREUdTa2vrQQw898MADzzzzTCaTGZYrP/HEE6dPn7548WLHMV+wYEGFFX1AqncVlprTyiuvvHI/Afytt97qNHrHjh1DPspmsy6L8TzvnnvuGfJpJQP69Kc/7apxI0aMmDlzZmWrhEsvvXRwGuJmqKZNm1ap282aNWvixInOFR922GGVIsz999+vta6vr1+2bNn7Tkz+67/+y8UzkydPXrVqFR8wUYNbDaeffrqUckiFYYgceuihZ5xxxjHHHLN3KJZOp4899ti1a9ceccQRp5566tt9w8yZM7/3ve99//vff/DBB1taWlKp1BlnnHHBBRdcfPHFQ3T2uOOOe/jhh++6664nnniiubl5+/btyWTyhBNOOPnkk8877zxHvHfO9uKLL06lUpUU5n3IRRddtGHDhu7u7uOPP/7AmZS36LhT8/7+/v1vGOEi5VKpNGQuz2mxo1jedNNNe59Y0fHvfOc7rqiwc+fOrVu3bt++fe+J4yF7IOzevbulpWXbtm2tra19fX1DfrUbz3Zt3w+ifcViMZ/PD+8GDu+Q5fu+v58ufiXf2Vu7nTzyyCNvvPHGyJEj984z985cPM97l4NYiLh/5ZVS7qcO/p5Cyb9CE0YM41q58847iejEE088sKvy71w+aKzS3d0dBIHv+7fccsuTTz6ZTqe/8IUvfAjrAUTcTWQh4urVq40x3/72t48++uj9OAzY1wzGh4i/BykWiytWrACAqVOn3nDDDVdeeeXb2i8hamtrK3+S5H+tfFDGfj6f7+7uRsREIlFbW7sfNoFrGJXL5erq6v/NoH84I/HXlg+5tX9t+f8HABOwDQwRgmWRAAAAAElFTkSuQmCC alt="Microsoft Hyper-V" style='float:Left'/>
<br><br>
<H1>Health Report: $($Computername.ToUpper())</H1>
<br><br><br>
"@

    $footer = @"
<p style='color:green'><i>Created $(Get-Date) by $($env:userdomain)\$($env:username)
<br>Brought to you by <a href='http://www.altaro.com/hyper-v/' target='_blank'>
Altaro</a></i>
<br><i>v$reportversion</i>
"@

    $paramHash = @{
        Head        = $head
        Body        = $fragments
        Postcontent = $footer
    }

    ConvertTo-Html @paramHash | Out-File -FilePath $path -encoding ASCII

    $progParam.status = "Creating HTML Report"
    $progParam.currentOperation = "Finished"
    $progParam.percentcomplete = 100
    Write-Progress @progParam -Completed

    Write-Host "Report complete. Please see $(Resolve-Path $path)" -ForegroundColor Green

    #endregion

} #close new report function