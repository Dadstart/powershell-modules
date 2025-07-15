function Move-PlexFile {
    <#
    .SYNOPSIS
        Moves bonus content to Plex folders.

    .DESCRIPTION
        This function takes a source and destination and moves all bonus content in the source directory to the Plex bonus content folders in the destination.

    .PARAMETER Source
        Source path where the bonus content files are located.

    .PARAMETER Destination
        Destination path where the bonus content should be moved.

    .PARAMETER Force
        Overwrites existing files without prompting. By default, Move-Item will prompt for confirmation if a file already exists.

    .EXAMPLE
        Move-PlexFile -Source 'C:\downloads\My Movie' -Destination 'C:\plex\movies\My Movie'

        Moves *-behindthescenes.* from source to 'C:\plex\movies\My Movie\Behind The Scenes'
        Moves *-deleted.* from source to 'C:\plex\movies\My Movie\Deleted Scenes'
        etc.

    .EXAMPLE
        Move-PlexFile -Source 'C:\downloads\My Movie' -Destination 'C:\plex\movies\My Movie' -Force

        Moves bonus content files, overwriting any existing files in the destination without prompting.

    .INPUTS
        [string] - The source and destination paths

    .OUTPUTS
        None. Moves files to appropriate Plex folders.

    .NOTES
        This function looks for files with specific suffixes in the source directory and moves them to appropriate Plex folders.
        The -Force parameter is passed through to Move-Item to control file overwrite behavior.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [Parameter()]
        [switch]$Force
    )

    if (-not (Test-Path -Path $Destination)) {
        Write-Error 'Destination folder does not exist' -ErrorAction Stop
    }
    if (-not (Test-Path -Path $Source)) {
        Write-Error 'Source folder does not exist' -ErrorAction Stop
    }

    $plexLayout = @{
        'Behind The Scenes' = 'behindthescenes'
        'Deleted Scenes'    = 'deleted'
        'Featurettes'       = 'featurette'
        'Interviews'        = 'interview'
        'Scenes'            = 'scene'
        'Shorts'            = 'short'
        'Trailers'          = 'trailer'
        'Other'             = 'other'
    }

    Write-Verbose 'Moving bonus content to Plex folders'
    $filesMoved = 0
    foreach ($folder in $plexLayout.Keys) {
        $fileSuffix = $plexLayout[$folder]
        $sourceFiles = @(Get-ChildItem -Path $Source -Recurse -Filter "*-$fileSuffix.mp4") + @(Get-ChildItem -Path $Source -Recurse -Filter "*-$fileSuffix.*srt")
        Write-Verbose "Found $($sourceFiles.Count) files to move for $folder"
        $destFolder = Join-Path -Path $Destination -ChildPath $folder
        if ($sourceFiles.Count -gt 0) {
            Write-Output "Moving $($sourceFiles.Count) files -$fileSuffix to $destFolder"
        }
        foreach ($sourceFile in $sourceFiles) {
            Write-Verbose "Moving $($sourceFile.Name) to $destFolder"
            Move-Item $sourceFile.FullName "$destFolder" -Force:$Force -ErrorAction Continue
            $filesMoved++
        }
    }

    if ($filesMoved -eq 0) {
        Write-Warning "No bonus content files found to move in source directory $Source"
    }
    else {
        Write-Verbose "$filesMoved files moved to Plex folders" -InformationAction Continue
    }
}