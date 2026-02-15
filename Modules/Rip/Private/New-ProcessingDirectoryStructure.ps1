function New-ProcessingDirectoryStructure {
    <#
    .SYNOPSIS
        Creates the complete directory structure for DVD processing.
    .DESCRIPTION
        Creates the organized directory structure required for DVD processing:
        - Root show directory
        - Season subdirectory
        - Processing subdirectories (HandBrake, Remux, Topaz, Bonus)
        - Provides detailed feedback about the creation process
        This function extracts the directory creation logic from Invoke-DvdProcessing
        to improve maintainability and testability.
    .PARAMETER Title
        The title of the content being processed.
    .PARAMETER Season
        The season number for the content.
    .PARAMETER SubDirectories
        Array of subdirectory names to create. Default includes standard processing directories.
    .PARAMETER BasePath
        Base path where the directory structure should be created. Default is current directory.
    .EXAMPLE
        $dirs = New-ProcessingDirectoryStructure -Title "Breaking Bad" -Season 1
        Creates the directory structure for Breaking Bad Season 1 in the current directory.
    .EXAMPLE
        $dirs = New-ProcessingDirectoryStructure -Title "The Office" -Season 3 -BasePath "D:\Shows" -SubDirectories @('HandBrake', 'Remux', 'Custom')
        Creates a custom directory structure for The Office Season 3 in D:\Shows.
    .OUTPUTS
        [PSCustomObject] Object containing created directory paths:
        - RootDir: Path to the root show directory
        - SeasonDir: Path to the season directory
        - SubDirs: Array of created subdirectory paths
    .NOTES
        This function requires the DVD module to be installed and available.
        Uses New-ProcessingDirectory for consistent directory creation.
        Creates all necessary subdirectories for different processing stages.
        Provides detailed verbose output for troubleshooting.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        [Parameter(Mandatory)]
        [ValidateRange(1, 99)]
        [int]$Season,
        [Parameter()]
        [ValidateNotNull()]
        [string[]]$SubDirectories = @('HandBrake', 'Remux', 'Topaz', 'Bonus'),
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$BasePath = '.'
    )
    return Invoke-WithErrorHandling -OperationName "Directory structure creation" -DefaultReturnValue @{ RootDir = $null; SeasonDir = $null; SubDirs = @() } -ErrorEmoji "📁" -ScriptBlock {
        Write-Message "📁 Creating directory structure for $Title Season $Season" -Type Processing
        Write-Message "Base path: $BasePath" -Type Verbose
        Write-Message "Subdirectories: $($SubDirectories -join ', ')" -Type Verbose
        # Create root directory
        $rootDir = New-ProcessingDirectory -Path (Get-Path -Path $BasePath, $Title -PathType Absolute) -Description "show"
        # Create season directory
        $seasonDir = New-ProcessingDirectory -Path (Get-Path -Path $rootDir, ('Season {0:D2}' -f $Season) -PathType Absolute) -Description "season"
        Write-Message "Processing $Title in $seasonDir" -Type Verbose
        # Create subdirectories for different processing stages
        $createdSubDirs = @()
        foreach ($subDir in $SubDirectories) {
            $subDirPath = Get-Path -Path $seasonDir, $subDir -PathType Absolute
            New-ProcessingDirectory -Path $subDirPath -Description $subDir -SuppressOutput | Out-Null
            $createdSubDirs += $subDirPath
            Write-Message "📂 Created subdirectory: $subDir" -Type Verbose
        }
        $result = [PSCustomObject]@{
            RootDir = $rootDir
            SeasonDir = $seasonDir
            SubDirs = $createdSubDirs
        }
        Write-Message "✅ Directory structure created successfully" -Type Verbose
        Write-Message "📂 Root: $rootDir" -Type Verbose
        Write-Message "📂 Season: $seasonDir" -Type Verbose
        Write-Message "📂 Subdirectories: $($createdSubDirs.Count)" -Type Verbose
        return $result
    }
}
