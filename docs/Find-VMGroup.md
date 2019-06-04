---
external help file: PSHyperV-help.xml
Module Name: PSHyperV
online version:
schema: 2.0.0
---

# Find-VMGroup

## SYNOPSIS

Find a VM Group by name and/or group type

## SYNTAX

### Name (Default)

```yaml
Find-VMGroup [-CimSession <CimSession[]>] [-ComputerName <String[]>] [-Credential <PSCredential[]>]
 [[-Name] <String[]>] [-GroupType <String>] [<CommonParameters>]
```

### Id

```yaml
Find-VMGroup [-CimSession <CimSession[]>] [-ComputerName <String[]>] [-Credential <PSCredential[]>]
 [[-Id] <Guid>] [-GroupType <String>] [<CommonParameters>]
```

## DESCRIPTION

This command is very similar to Get-VMGroup and is not much more than a "wrapper" function for that command. The primary difference is that you can use this command to limit groups to a specific type. Although the default is to find all VM groups.

## EXAMPLES

### Example 1

```powershell
PS C:\> Find-VMGroup -GroupType ManagementCollectionType -computername HV-Master


Name           : Company
InstanceId     : cb355d34-3dd6-4e31-ba2c-53470b95fc9c
GroupType      : ManagementCollectionType
VMMembers      :
VMGroupMembers : {CompanyDC, CompanyMembers}
CimSession     : CimSession: .
ComputerName   : HV-Master
IsDeleted      : False

Name           : Master
InstanceId     : d105e734-0e00-4eb0-a0c8-6c6e21c7956c
GroupType      : ManagementCollectionType
VMMembers      :
VMGroupMembers : {CompanyDC, LinuxVMs, CompanyMembers}
CimSession     : CimSession: .
ComputerName   : HV-Master
IsDeleted      : False
```

Get all VM management groups.

## PARAMETERS

### -CimSession

Connect to a remote Hyper-V host using an existing CimSession.

```yaml
Type: CimSession[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName

The name of a Hyper-V host.

```yaml
Type: String[]
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupType

You can filter results by the VM group type. The default is all groups.

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

### -Id

A VM group ID.

```yaml
Type: Guid
Parameter Sets: Id
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

The name of a VM Group.

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### Microsoft.HyperV.PowerShell.VMGroup

## NOTES

Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/

## RELATED LINKS

[Get-VMGroup]()

[Expand-VMGroup]()