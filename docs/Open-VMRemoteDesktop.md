---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Open-VMRemoteDesktop

## SYNOPSIS

Open a virtual machine using Remote Desktop.

## SYNTAX

```yaml
Open-VMRemoteDesktop [-Name] <String> [-Computername <String>] [-Admin] [-FullScreen] [<CommonParameters>]
```

## DESCRIPTION

Connect to a given virtual machine using a remote desktop connection. This assumes a Windows operating system on the virtual machine and it has been configured to allow remote desktop connections. The connection is made via the virtual machine's IP address. If connecting to a virtual machine on a remote computer it must have a publicly accessible IP address and interface.

## EXAMPLES

### Example 1

```powershell
PS C:\> Open-VMRemoteDesktop Win10 -fullscreen
```

Connect to the virtual machine Win10 on the local machine via remote desktop full screen. You may be prompted for credentials.

## PARAMETERS

### -Admin

Connect to remote desktop session used for administering a remote computer.

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

### -FullScreen

Run in full screen mode.

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

Enter a Hyper-V virtual machine name. The virtual machine needs a publicly accessible IP address.

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

[Open-VMConnect]()