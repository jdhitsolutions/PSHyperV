---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Get-VMMemorySummary

## SYNOPSIS

Get a VM memory summary

## SYNTAX

### NamebyComputer (Default)

```yaml
Get-VMMemorySummary [[-Name] <String[]>] [-ComputerName <String[]>] [-Credential <PSCredential[]>]
 [<CommonParameters>]
```

### NamebySession

```yaml
Get-VMMemorySummary [[-Name] <String[]>] [-CimSession <CimSession[]>] [<CommonParameters>]
```

### VM

```yaml
Get-VMMemorySummary [-VM <VirtualMachine[]>] [<CommonParameters>]
```

### IdbySession

```yaml
Get-VMMemorySummary [-CimSession <CimSession[]>] [[-Id] <Guid>] [<CommonParameters>]
```

### IdbyComputer

```yaml
Get-VMMemorySummary [-ComputerName <String[]>] [-Credential <PSCredential[]>] [[-Id] <Guid>]
 [<CommonParameters>]
```

## DESCRIPTION

This command gets memory settings for a given Hyper-V virtual machine. All memory values are in MB.

## EXAMPLES

### Example 1

```powershell

PS C:\> Get-VM Win10 | Get-VMMemorySummary

Name  Dynamic AssignedMB DemandMB StartMB MinMB MaxMB
----  ------- ---------- -------- ------- ----- -----
WIN10 True    2048       880      2048    2048  1048576
```

Get a memory report for a single virtual machine. Note that the output is formatted as a table by default.

### Example 2

```powershell
PS C:\> Get-VMMemorySummary dom1 | select *


Name         : DOM1
Dynamic      : True
Assigned     : 2048
Demand       : 962
Startup      : 2048
Minimum      : 2048
Maximum      : 1048576
Buffer       : 20
Priority     : 50
Computername : BOVINE320
Date         : 6/4/2019 12:23:27 PM
```

### Example 3

```powershell
PS C:\> Get-VMState -State Running -ComputerName HV01 | Get-VMMemorySummary | Where-object {$_.demand -ge 1024} | Select-object * | Out-Gridview -title "Memory Report"
```

Get a memory report for all running virtual machines on server HV01 that have a memory demand greater than 1024MB and display the results with Out-Gridview.

## PARAMETERS

### -Name

The name of the virtual machine or a Hyper-V virtual machine object. This parameter has an alias of "VM"

```yaml
Type: String[]
Parameter Sets: NamebyComputer
Aliases: VMName

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

```yaml
Type: String[]
Parameter Sets: NamebySession
Aliases: VMName

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -VM

A virtual machine object.

```yaml
Type: VirtualMachine[]
Parameter Sets: VM
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -CimSession

An existing CIMSession object to a Hyper-V host.

```yaml
Type: CimSession[]
Parameter Sets: NamebySession, IdbySession
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName

The name of the Hyper-V server to query. The default is the local host.

```yaml
Type: String[]
Parameter Sets: NamebyComputer, IdbyComputer
Aliases:

Required: False
Position: Named
Default value: localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

An alternate credential to be used with the Computername.

```yaml
Type: PSCredential[]
Parameter Sets: NamebyComputer, IdbyComputer
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
Parameter Sets: IdbySession, IdbyComputer
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

## OUTPUTS

### vmMemorySummary

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-VM]()

[Get-VMMemory]()
