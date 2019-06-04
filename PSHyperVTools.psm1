
#dot source module functions

. $PSScriptRoot\functions\public.ps1

#add a custom type extension
$typename = "Microsoft.HyperV.PowerShell.VirtualMachine"

$sb = {
    (Get-VMGroup -ComputerName $this.computername).where( {$_.grouptype -eq "ManagementCollectionType" -AND $_.vmgroupmembers.vmmembers.name -contains $this.name})
}

Update-TypeData -TypeName $typename -MemberType ScriptProperty -MemberName ManagementGroups -Value $sb -force