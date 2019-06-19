---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Set-VMNote

## SYNOPSIS

Modify the Notes setting of a virtual machine.

## SYNTAX

### Name (Default)

```yaml
Set-VMNote [-Name] <String[]> [-Notes <String>] [-Action <String>] [-Passthru] [-ComputerName <String>]
 [-WhatIf] [-Confirm] [-Credential <PSCredential>] [<CommonParameters>]
```

### VMObject

```yaml
Set-VMNote [-VM] <VirtualMachine[]> [-Notes <String>] [-Action <String>] [-Passthru] [-WhatIf] [-Confirm]
 [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

To modify the Notes settings for a Hyper-V virtual machine, you could use Set-VM. However, that command has a few limitations which this version addresses. You can use this command to append a note or to clear notes entirely. This command uses a PowerShell remoting session (PSSession) to implement the change. If you used a credential to get virtual machine from a remote computer, you'll need to use it again to set the note. The -Credential parameter is only available if the computername or virtual machine computername property does not match the local computername.

## EXAMPLES

### Example 1

```powershell
PS C:\> Set-VMNote srv1,srv2,dom1 -computername srv02 -note "Updated $(Get-Date)' -action Create -passthru | Select-object -property Computername,Name,Notes

ComputerName Name Notes
------------ ---- -----
SRV02        SRV1 Updated 06/19/2019 16:00:...
SRV02        SRV2 Updated 06/19/2019 16:00:...
SRV02        DOM1 Updated 06/19/2019 16:00:...
```

Set a new note on 3 virtual machines on Hyper-V host SRV02.

### Example 2

```powershell
PS C:\> $vm = Get-VM win10 -ComputerName srv02 -Credential srv02\jeff
PS C:\> $vm | select-object name,notes

Name  Notes
----  -----
WIN10 Running Windows 10 Enterprise
PS C:\> Set-VMNote $vm -Notes "Marked for removal 7/1/2019" -Action Append -Credential "$($vm.computername)\jeff"
PS C:\>  $vm.notes
Running Windows 10 Enterprise
Marked for removal 7/1/2019
```

The first part of this example gets a virtual machine from a remote host using an alternate credential. The second command shows the current notes. The last part of the example appends a note. Since a credential was used to get the VM originally it is assumed you need the credential to set the note. The end result is then displayed.

## PARAMETERS

### -Action

Specify what action to take with the note.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Create, Append, Clear

Required: False
Position: Named
Default value: Create
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName

Enter the name of a Hyper-V host. The default is the localhost.

```yaml
Type: String
Parameter Sets: Name
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

Enter an alternate credential in the form domain\username or computername\username. If you used a credential to get the VM in any way, then you need to re-use it to set the note. This parameter is only available if the computername or computername property of the virtual machine is not equal to the localhost.

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

Enter the name of a virtual machine.

```yaml
Type: String[]
Parameter Sets: Name
Aliases: VMName

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Notes

Enter the text for the note. You can ignore this parameter when clearing a note.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Passthru

Write the VM object to the pipeline.

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

### -VM

A Hyper-V virtual machine object.

```yaml
Type: VirtualMachine[]
Parameter Sets: VMObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Microsoft.HyperV.PowerShell.VirtualMachine[]

### System.String[]

## OUTPUTS

### None

### Microsoft.HyperV.PowerShell.VirtualMachine[]

## NOTES

Learn more about PowerShell: http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Set-VM]()
