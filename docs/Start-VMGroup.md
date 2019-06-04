---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Start-VMGroup

## SYNOPSIS

Start all members of a VM group that are not already running.

## SYNTAX

```yaml
Start-VMGroup [[-Name] <String>] [-Computername <String>] [-Credential <PSCredential>] [-AsJob] [-Passthru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This command will expand virtual machine members of a VM group and start the virtual machine if it is not already running.

## EXAMPLES

### Example 1

```powershell
PS C:\> Start-VMGroup company -Computername HV-Master -Passthru

Name State   CPUUsage(%) MemoryAssigned(M) Uptime   Status             Version
---- -----   ----------- ----------------- ------   ------             -------
SRV1 Running 0           0                 00:00:00 Operating normally 9.0
SRV2 Running 0           0                 00:00:00 Operating normally 9.0
```

Start the members of the Company VM group on HV-Master that are not already running.

## PARAMETERS

### -AsJob

Start the virtual machines in a background job.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Computername

The name of a Hyper-V host.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: localhost
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

An alternate credential to be used with Computername.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

The name of the VM Group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Passthru

Write the virtual machine object to the pipeline

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### None

### Microsoft.HyperV.PowerShell.VirtualMachine

### Microsoft.HyperV.PowerShell.Commands.VmJob

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Expand-VMGroup]()

[Stop-VMGroup]()