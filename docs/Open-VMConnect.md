---
external help file: PSHyperV-help.xml
Module Name: PSHyperV
online version:
schema: 2.0.0
---

# Open-VMConnect

## SYNOPSIS

Connect to virtual machine using VMConnect.

## SYNTAX

```yaml
Open-VMConnect [-Name] <String> [-Computername <String>] [<CommonParameters>]
```

## DESCRIPTION

This is a PowerShell command to make it easier to connect to a virtual machine console using the VMConnect.exe command line tool. You must run this under an account that has admin rights on the remote Hyper-V host.

## EXAMPLES

### Example 1

```powershell
PS C:\> open-vmconnect srv1 -Computername HV-01
```

Launch VMConnect and connect to virtual machine SRV1 on HV-01.

## PARAMETERS

### -Computername

The name of the Hyper-V host.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: localhost
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name

Enter a Hyper-V virtual machine name

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### None

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Open-VMRemoteDesktop]()