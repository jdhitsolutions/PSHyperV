
#dot source module functions

. $PSScriptRoot\functions\public.ps1
. $PSScriptRoot\functions\private.ps1

#add custom type extensions

$extensions = get-content $PSScriptRoot\hyperv-vm.extensions.json | ConvertFrom-Json | foreach-Object { $_ }
foreach ($update in $extensions) {
    $val = [scriptblock]::create($update.value)
    Update-TypeData -typename $update.typename -MemberType $update.MemberType -MemberName $update.MemberName -Value $val -force
}

<#
notes

Get-CimInstance -Namespace root/virtualization/v2 -ClassName msvm_computersystem |
select elementname,timeoflastStateChange

#>

