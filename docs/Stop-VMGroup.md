---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Stop-VMGroup

## SYNOPSIS

Stop all members of a VM group that are not already running.

## SYNTAX

```yaml
Stop-VMGroup [[-Name] <String>] [-Computername <String>] [-Credential <PSCredential>] [-Force] [-Save]
 [-TurnOff] [-AsJob] [-Passthru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This command will expand virtual machine members of a VM group and stop the virtual machine if it running.

## EXAMPLES

### Example 1

```powershell
PS C:\> Stop-VMGroup master -Computername HV-01 -AsJob -force
```

Stop all members of the Master VM group on HV-01 using a background job.

### Example 2

```powershell
PS C:\> Stop-VMGroup linuxvms -Save -Passthru -Computername hv-master

Name   State CPUUsage(%) MemoryAssigned(M) Uptime           Status             Version
----   ----- ----------- ----------------- ------           ------             -------
CentOS Saved 0           978               00:10:40.4110000 Operating normally 8.0
```

Stop all running members of the LinuxVMS group on HV-Master, saving their state.

## PARAMETERS

### -AsJob

Stop the virtual machines using a background job.

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

### -Force

Specifies that the shutdown of the virtual machine is to be forced. If the virtual machine has applications with
unsaved data, the virtual machine has five minutes to save data and shut down. If the virtual machine is locked,
it is shut down immediately.

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

### -Name

The name of a VM group.

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

Write the virtual machine object to the pipeline.

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

### -Save

Specifies that the virtual machine is to be saved.

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

### -TurnOff

Specifies that the virtual machine is to be turned off.

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

[Start-VMGroup]()
