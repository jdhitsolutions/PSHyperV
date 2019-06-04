
Function Expand-VMGroup {
    [cmdletbinding()]
    [outputtype("myGroupVM")]

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
                        $item.name
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
        "force", "save", "asjob". "turnoff", "passthru", "whatif", "confirm" | foreach-object {
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

<#
This is a copy of:

CommandType Name        Version Source
----------- ----        ------- ------
Cmdlet      Get-VMGroup 2.0.0.0 Hyper-V

Created: 03 June 2019
Author : Jeff

#>


Function Get-VMGroup {
    <#
.ForwardHelpTargetName Hyper-V\Get-VMGroup
.ForwardHelpCategory Cmdlet

#>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
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

        Write-Verbose "[BEGIN  ] Starting $($MyInvocation.Mycommand)"
        Write-Verbose "[BEGIN  ] Using parameter set $($PSCmdlet.ParameterSetName)"
        Write-Verbose ($PSBoundParameters | Out-String)

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

        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }


    } #process

    End {

        Write-Verbose "[END    ] Ending $($MyInvocation.Mycommand)"

        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }

    } #end

} #end function Get-VMGroup