function Add-PlexFolder {
    <#
    .SYNOPSIS
        Adds Plex folders for bonus content.

    .DESCRIPTION
        This function takes a destination and creates the Plex bonus content folders.

    .PARAMETER Destination
        Destination path where the folders should be created.

    .EXAMPLE
        Add-PlexFolders 'C:\plex\movies\My Movie'

        Creates folder 'C:\plex\movies\My Movie\Behind The Scenes'
        Creates folder 'C:\plex\movies\My Movie\Deleted Scenes'
        etc.

    .INPUTS
        [string] - The destination path

    .OUTPUTS
        None. Creates directories in the specified destination.

    .NOTES
        This function creates the standard Plex bonus content folder structure.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -Path $Destination)) {
        Write-Error 'Destination folder does not exist' -ErrorAction Stop
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

    foreach ($folder in $plexLayout.Keys) {
        $path = Join-Path -Path $Destination -ChildPath $folder
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -ItemType Directory | Out-Null
            Write-Verbose "Created folder: $path"
        }
    }
    Write-Verbose 'Plex folders created'
}