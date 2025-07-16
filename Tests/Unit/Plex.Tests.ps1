Describe 'Plex Module' {
    BeforeAll {
        # Import the entire Plex module
        Import-Module '.\Modules\Plex\PlexTools.psm1' -Force
    }
    # Import individual function tests
    # TODO: Add Plex function tests as they are created
    # . "$PSScriptRoot\Plex\Get-PlexCredential.Tests.ps1"
    # . "$PSScriptRoot\Plex\Get-PlexLibraries.Tests.ps1"
    # . "$PSScriptRoot\Plex\Get-PlexLibraryItems.Tests.ps1"
    # . "$PSScriptRoot\Plex\Get-PlexMediaInfo.Tests.ps1"
    # . "$PSScriptRoot\Plex\Get-PlexServerInfo.Tests.ps1"
    # . "$PSScriptRoot\Plex\Invoke-PlexLibraryScan.Tests.ps1"
    # . "$PSScriptRoot\Plex\Test-PlexConnection.Tests.ps1"
}
