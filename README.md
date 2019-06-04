# PSHyperVTools

[![PSGallery Version](https://img.shields.io/powershellgallery/v/PSHyperVTools.png?style=for-the-badge&logo=powershell&label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/PSHyperVTools/) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/PSHyperVTools.png?style=for-the-badge&label=Downloads)](https://www.powershellgallery.com/packages/PSHyperVTools/)

A set of PowerShell tools for working with Hyper-V from a Windows 10 desktop. You must have the Hyper-V PowerShell module installed. **This module is under active development**

## Installation

You can install the current release from the PowerShell Gallery:

```powershell
Install-Module PSHyperVTools [-scope currentuser]
```

Please post any questions, problems, suggestions or comments in the Issues section of this repository.

## Commands

Many of the commands in this module are "wrapper" or proxy variations of native Hyper-V cmdlets that are designed to be easier to use in an interactive PowerShell session.

### [Expand-VMGroup](docs\Expand-VMGroup.md)

When using VM groups, such as with Get-VMGroup, the resulting object displays nested VM or Management collections. But
often, the whole point of a group is to make it easier to work with the collected virtual machines. This command will
expand all virtual machines in a given group. You can also return a simple list of the virtual machine names.

### [Find-VMGroup](docs\Find-VMGroup.md)

This command is very similar to Get-VMGroup and is not much more than a "wrapper" function for that command. The
primary difference is that you can use this command to limit groups to a specific type. Although the default is to
find all VM groups.

### [Get-VMIPAddress](docs\Get-VMIPAddress.md)

This command is designed to get the IPv4 address for a given set of Hyper-V virtual machines. It assumes a single
network adapter in each virtual machine with a single IPv4 address. The command has not been tested with other
networking configurations such as NIC teaming.

### [Get-VMMemorySummary](docs\Get-VMMemorySummary.md)

This command gets memory settings for a given Hyper-V virtual machine.

### [Get-VMState](docs\Get-VMState.md)

One of the drawbacks to the Get-VM command in the Hyper-V module is that it provides no filtering mechanism on the
state, such as running. If you often find yourself running Get-VM and piping to Where-Object to only get running or
stopped virtual machines, this command will simplify that process. The default behavior is to display all running
virtual machines.

### [Open-VMConnect](docs\Open-VMConnect.md)

This is a PowerShell command to make it easier to connect to a virtual machine console using the VMConnect.exe command
line tool. You must run this under an account that has admin rights on the remote Hyper-V host.

### [Open-VMRemoteDesktop](docs\Open-VMRemoteDesktop.md)

Connect to a given virtual machine using a remote desktop connection. This assumes a Windows operating system on the
virtual machine and it has been configured to allow remote desktop connections. The connection is made via the virtual
machine's IP address. If connecting to a virtual machine on a remote computer it must have a publicly accessible IP
address and interface.

### [Start-VMGroup](docs\Start-VMGroup.md)

This command will expand virtual machine members of a VM group and start the virtual machine if it is not already
running.

### [Stop-VMGroup](docs\Stop-VMGroup.md)

This command will expand virtual machine members of a VM group and stop the virtual machine if it running.

_Last updated 2019-06-04 16:19:53Z_
