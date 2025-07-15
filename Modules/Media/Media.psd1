@{
    # Version number of this module.
    ModuleVersion = '0.0.1'
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    
    # Author of this module
    Author = 'Dadstart'
    
    # Company or vendor of this module
    CompanyName = 'Dadstart'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Dadstart. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'PowerShell module for media file management and processing operations.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.4'
    
    # Name of the PowerShell host required by this module
    PowerShellHostName = ''
    
    # Minimum version of the PowerShell host required by this module
    PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @('Types\Media.types.ps1xml')
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @('Formats\Media.format.ps1xml')
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @('Media.psm1')
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Get-MediaInfo',
        'Convert-Media',
        'Optimize-Media',
        'Get-MediaMetadata'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # DSC resources to export from this module
    DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Media', 'Video', 'Audio', 'Conversion', 'Optimization')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Dadstart/powershell-modules/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Dadstart/powershell-modules'
            
            # A URL to an icon representing this module.
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Media module'
            
            # Prerelease string of this module
            Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/Dadstart/powershell-modules/issues'
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    DefaultCommandPrefix = ''
} 