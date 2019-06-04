#
# Module manifest for module PSHyperV
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'PSHyperV.psm1'

    # Version number of this module.
    ModuleVersion = '0.2.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')

    # ID used to uniquely identify this module
    GUID = 'f8d8459c-9a39-4eee-a869-0da58e358d36'

    # Author of this module
    Author = 'Jeff Hicks'

    # Company or vendor of this module
    CompanyName = 'JDH Information Technology Solutions, Inc.'

    # Copyright statement for this module
    Copyright = '(c) 2019 Jeff Hicks. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A set of PowerShell tools for working with Hyper-V'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @('Hyper-V')

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('mygroupvm.format.ps1xml','VMIPAddress.format.ps1xml','.\vmMemorySummary.format.ps1xml')

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = 'Stop-VMGroup','Start-VMGroup','Expand-VMGroup',
    'Find-VMGroup','Get-VMIPAddress','Open-VMRemoteDesktop','Open-VMConnect',
    'Get-VMState','Get-VMMemorySummary'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = ''

    # Variables to export from this module
    # VariablesToExport = ''

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    # AliasesToExport = ''

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @("HyperV","Hyper-V")

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/jdhitsolutions/PSHyperV/blob/master/license.txt'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/jdhitsolutions/PSHyperV'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

    }



