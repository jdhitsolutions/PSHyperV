

Function _getConfigFile {
    [cmdletbinding()]
    Param(
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM
    )

    $ps = (get-pssession).where({$_.computername -eq $vm.computername -AND $_.state -eq "opened"}) | select-object -first 1

    if (-not $ps) {
        $ps = New-pssession -computername $vm.computername
    }

    invoke-Command { join-path "$($using:vm.configurationlocation)\virtual machines" -ChildPath "$($using:VM.vmid).vmcx" -Resolve} -session $ps
}