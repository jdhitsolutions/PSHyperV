---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Get-VMState

## SYNOPSIS

Get a virtual machine by its state.

## SYNTAX

### Name (Default)

```yaml
Get-VMState [[-Name] <String[]>] [-CimSession <CimSession[]>] [-ComputerName <String[]>]
 [-Credential <PSCredential[]>] [-State <VMState>] [<CommonParameters>]
```

### Id

```yaml
Get-VMState [-CimSession <CimSession[]>] [-ComputerName <String[]>] [-Credential <PSCredential[]>]
 [[-Id] <Guid>] [-State <VMState>] [<CommonParameters>]
```

### ClusterObject

```yaml
Get-VMState [-ClusterObject] <PSObject> [-State <VMState>] [<CommonParameters>]
```

## DESCRIPTION

One of the drawbacks to the Get-VM command in the Hyper-V module is that it provides no filtering mechanism on the state, such as running. If you often find yourself running Get-VM and piping to Where-Object to only get running or stopped virtual machines, this command will simplify that process. The default behavior is to display all running virtual machines.

## EXAMPLES

### Example 1

```powershell
PS C:\> Get-VMState -State Off -ComputerName HV-01

Name        State CPUUsage(%) MemoryAssigned(M) Uptime   Status             Version
----        ----- ----------- ----------------- ------   ------             -------
Fedora28    Off   0           0                 00:00:00 Operating normally 8.3
WS2019_Base Off   0           0                 00:00:00 Operating normally 9.0
```

Get all virtual machines on HV-01 that are not running.

### Example 2

```powershell
PS C:\> Get-VMState -computername HV-Master | Get-VMMemory

VMName DynamicMemoryEnabled Minimum(M) Startup(M) Maximum(M)
------ -------------------- ---------- ---------- ----------
DOM1   True                 2048       2048       1048576
SRV1   True                 1024       2048       1048576
SRV2   True                 1024       2048       1048576
SRV3   True                 1024       1024       1048576
SRV4   True                 512        4096       1048576
WIN10  True                 2048       2048       1048576
```

Get all running virtual machines on HV-Master and pipe the virtual machine objects to Get-VMMemory.

## PARAMETERS

### -CimSession

An existing CIMSession to a Hyper-V host.

```yaml
Type: CimSession[]
Parameter Sets: Name, Id
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClusterObject


```yaml
Type: PSObject
Parameter Sets: ClusterObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerName

The name of a Hyper-V host.

```yaml
Type: String[]
Parameter Sets: Name, Id
Aliases:

Required: False
Position: Named
Default value: localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

An alternate credential to be used with Computername.

```yaml
Type: PSCredential[]
Parameter Sets: Name, Id
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id

A virtual machine ID.

```yaml
Type: Guid
Parameter Sets: Id
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name

The name of a virtual machine.

```yaml
Type: String[]
Parameter Sets: Name
Aliases: VMName

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -State

The virtual machine state to filter for.

```yaml
Type: VMState
Parameter Sets: (All)
Aliases:
Accepted values: Other, Running, Off, Stopping, Saved, Paused, Starting, Reset, Saving, Pausing, Resuming, FastSaved, FastSaving, ForceShutdown, ForceReboot, Hibernated, RunningCritical, OffCritical, StoppingCritical, SavedCritical, PausedCritical, StartingCritical, ResetCritical, SavingCritical, PausingCritical, ResumingCritical, FastSavedCritical, FastSavingCritical

Required: False
Position: Named
Default value: Running
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

### System.Guid[]

### System.Object[]

## OUTPUTS

### Microsoft.HyperV.PowerShell.VirtualMachine

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-VM]()