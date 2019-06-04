
#these are functions to be exported and visible to the user

#todo - Get-VHDSummary
Function Expand-VMGroup {
    [cmdletbinding()]
    [outputtype("myGroupVM","String")]

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
        "force", "save", "asjob","turnoff", "passthru", "whatif", "confirm" | foreach-object {
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
            $PSBoundParameters.Remove('State') | Out-Null
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
