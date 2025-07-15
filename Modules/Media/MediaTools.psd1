@{
    # Version number of this module.
    ModuleVersion = '0.0.2'

    # ID used to uniquely identify this module
    GUID = '9576456d-df0a-4111-add7-cd1514abd233'

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

    # Root module that applies when this module is imported
    RootModule = 'MediaTools.psm1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Add-MediaStream',
        'Add-PlexFolder',
        'Convert-ToConstantFrameRate',
        'ConvertTo-MediaStreamCollection',
        'Export-AudioStream',
        'Export-Chapter',
        'Export-MediaStream',
        'Export-MediaStreamCollection',
        'Export-MediaStreams',
        'Export-SubtitleStream',
        'FFProbeResult',
        'Find-StringInFiles',
        'Get-AudioData',
        'Get-AudioMetadataMap',
        'Get-AudioStream',
        'Get-Bitrate',
        'Get-Bitrates',
        'Get-ChapterInfo',
        'Get-EnhancedTitle',
        'Get-EpisodeInfoFromFilename',
        'Get-FFMpegVersion',
        'Get-MediaExtension',
        'Get-MediaStats',
        'Get-MediaStream',
        'Get-MediaStreamCollection',
        'Get-MediaStreams',
        'Get-MkvTrack',
        'Get-MkvTrackAll',
        'Get-MkvTracks',
        'Get-MultipleAudioStreams',
        'Get-SubtitleStream',
        'Get-SystemSnapshot',
        'Get-TvDbEpisodeIds',
        'Get-TvDbEpisodeInfo',
        'Invoke-CaptionExtraction',
        'Invoke-ChapterExtraction',
        'Invoke-CheckedCommand',
        'Invoke-FFMpeg',
        'Invoke-FFProbe',
        'Invoke-PlexFileOperation',
        'Invoke-Process',
        'Invoke-SafeFileRename',
        'Invoke-VideoCopy',
        'MediaStreamInfo',
        'MediaStreamInfoCollection',
        'Move-PlexFile',
        'ProcessResult',
        'Remove-PlexEmptyFolder',
        'Show-SystemSnapshot',
        'Start-SystemMonitoring'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Media', 'Video', 'Audio', 'Conversion', 'Optimization')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Dadstart/powershell-modules/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Dadstart/powershell-modules'

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Media module'

            # Prerelease string of this module
            Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false
        }
    }

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/Dadstart/powershell-modules/issues'
} 