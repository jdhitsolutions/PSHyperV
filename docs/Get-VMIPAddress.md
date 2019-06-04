---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Get-VMIPAddress

## SYNOPSIS

Get virtual machine IP v4 information

## SYNTAX

### computer (Default)

```yaml
Get-VMIPAddress [-Name] <Object> [-Computername <String>] [-Credential <PSCredential>] [<CommonParameters>]
```

### session

```yaml
Get-VMIPAddress [-Name] <Object> [-Cimsession <CimSession>] [<CommonParameters>]
```

## DESCRIPTION

This command is designed to get the IPv4 address for a given set of Hyper-V virtual machines. It assumes a single network adapter in each virtual machine with a single IPv4 address. The command has not been tested with other networking configurations such as NIC teaming.

## EXAMPLES

### Example 1

```powershell
PS C:\> get-vmipaddress win10 -computername HV-Master

Name  IPAddress     MACAddress   Switch Computername
----  ---------     ----------   ------ ------------
WIN10 192.168.3.100 00155D0A364F LabNet HV-Master
```

Get IP address information for the Win10 virtual machine running on HV-Master.

### Example 2

```powershell
PS C:\> Get-VMState -state running -CimSession $cs | Get-VMIPAddress

Name  IPAddress     MACAddress   Switch Computername
----  ---------     ----------   ------ ------------
DOM1  192.168.3.10  00155D4E720E LabNet HV-01
SRV1  192.168.3.50  00155D4E7210 LabNet HV-01
SRV2  192.168.3.51  00155D4E7211 LabNet HV-01
SRV3  192.168.3.60  00155D4E7212 LabNet HV-01
WIN10 192.168.3.100 00155D4E720F LabNet HV-01
```

Get all running virtual machines using an existing CIMsession and pipe to Get-VMIPAddress.

## PARAMETERS

### -Cimsession

Connect to a Hyper-V host using an existing CIMSession.

```yaml
Type: CimSession
Parameter Sets: session
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
Parameter Sets: computer
Aliases:

Required: False
Position: Named
Default value: localhost
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Credential

An alternate credential to use with Computername.

```yaml
Type: PSCredential
Parameter Sets: computer
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

Enter a Hyper-V virtual machine name

```yaml
Type: Object
Parameter Sets: (All)
Aliases: vm

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

### System.Object

### System.String

## OUTPUTS

### vmIPAddress

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-VM]()

[Get-VMNetworkAdapter]()
