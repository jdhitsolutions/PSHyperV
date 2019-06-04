---
external help file: PSHyperVTools-help.xml
Module Name: PSHyperVTools
online version:
schema: 2.0.0
---

# Expand-VMGroup

## SYNOPSIS

Expand the virtual machine members of a VM Group

## SYNTAX

```yaml
Expand-VMGroup [[-Name] <String>] [-Computername <String>] [-Credential <PSCredential>] [-GroupType <String>]
 [-List] [<CommonParameters>]
```

## DESCRIPTION

When using VM groups, such as with Get-VMGroup, the resulting object displays nested VM or Management collections. But often, the whole point of a group is to make it easier to work with the collected virtual machines. This command will expand all virtual machines in a given group. You can also return a simple list of the virtual machine names.

## EXAMPLES

### Example 1

```powershell
PS C:\> Expand-VMGroup -Name company

VMGroup Name  State   Uptime             Status             Computername
------- ----  -----   ------             ------             ------------
Company DOM1  Running 4.04:08:12.7640000 Operating normally HV-Master
Company WIN10 Running 4.04:08:13.0420000 Operating normally HV-Master
Company SRV1  Running 4.04:08:12.5300000 Operating normally HV-Master
Company SRV2  Running 4.04:08:12.3590000 Operating normally HV-Master
```

Display all the virtual machines in the Company VM Group.

### Example 2

```powershell
PS C:\> Expand-VMGroup -GroupType ManagementCollectionType -Computername HV01

VMGroup Name     State   Uptime           Status             Computername
------- ----     -----   ------           ------             ------------
Master  Fedora28 Off     00:00:00         Operating normally HV01
Master  WIN10    Running 21:54:42.5620000 Operating normally HV01
Master  SRV1     Running 21:54:42.5620000 Operating normally HV01
Master  SRV2     Running 21:54:42.8620000 Operating normally HV01
Master  DOM1     Running 21:54:42.7720000 Operating normally HV01
Master  SRV3     Running 21:54:43.2430000 Operating normally HV01
```

Get all virtual machines in management collection groups on server HV01.

### Example 3

```powershell
PS C:\> Expand-VMGroup -Name CompanyMembers -list
WIN10
SRV1
SRV2
```

Get the virtual machine names as a list from the CompanyMembers group.

### Example 4

```powershell
PS C:\> Expand-VMGroup -Name CompanyMembers -list | Get-VMIPAddress

Name  IPAddress     MACAddress   Switch Computername
----  ---------     ----------   ------ ------------
WIN10 192.168.3.100 00155D0A364F LabNet HV-Master
SRV1  192.168.3.50  00155D0A3650 LabNet HV-Master
SRV2  192.168.3.51  00155D0A3651 LabNet HV-Master
```

Get the list of virtual machines from CompanyMembers and pipe to Get-VMIPAddress.

## PARAMETERS

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

### -Credential

An alternate credential to use with Computername.

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

### -GroupType

You can filter your results by a group type. The default is all groups.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: VMCollectionType, ManagementCollectionType

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -List

Return a text list of virtual machine names. The list will be of unique virtual machine names.

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

A VM group name.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.String

### myGroupVM

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-VMGroup]()