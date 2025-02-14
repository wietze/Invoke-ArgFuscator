@{

    # Script module or binary module file associated with this manifest.
    RootModule        = 'Invoke-ArgFuscator.psm1'

    # Version number of this module.
    ModuleVersion     = '1.1.0'

    # ID used to uniquely identify this module
    GUID              = '844d9edc-57ad-4fcc-9fd5-77a69d4bf569'

    # Author of this module
    Author            = 'wietze'

    # Description of the functionality provided by this module
    Description       = 'A PowerShell module that generate obfuscated command-lines for common system-native executables'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules   = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    ScriptsToProcess  = @()

    # Functions to export from this module
    FunctionsToExport = @('Invoke-ArgFuscator')

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/wietze/Invoke-ArgFuscator/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/wietze/Invoke-ArgFuscator'
        }
    }

    NestedModules     = @()

}
