# PowerShell script to connect to a Plex server and copy a playlist from one user to another.
# This script requires the Plex API to be accessible and the user to have the necessary permissions.
Add-Type -Path "C:\Users\Andrew\AppData\Local\Temp\PlexAPI.SDK\lib\net8.0\LukeHagar.PlexAPI.SDK.dll"
# Ensure the PlexAPI SDK is installed and available in the specified path.

class PlexLogin {
    [pscredential]$Credential
    [string]$ServerUrl
    [string]$Token

    PlexLogin([string]$credential, [string]$serverUrl, [string]$token) {
        $this.Credential = $credential
        $this.ServerUrl = $serverUrl
        $this.Token = $token
    }
}

function New-PlexLogin {
    [CmdletBinding()]
    param (
        [Parameter()]
        [pscredential]$Credential
    )

    if (-not $Credential) {
        $Credential = Get-Credential -Message "Enter your Plex credentials"
    }
    # Create a new Plex login object
    $token = Get-PlexServerToken -Credential $Credential
    $server = "http://localhost:32400"

    $login = New-Object PlexLogin($Credential, $server, $token)
    return $login
}
<#
function Get-PlexPlaylists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [LukeHagar.PlexAPI.SDK.PlexLogin]$Login
    )

#   $playlistTitle = "Spy Thrillers"        # Name of the playlist to copy

    # === GET PLAYLIST ITEMS ===
    $plexToken = Get-PlexServerToken -Credential $credential
    $headers = @{ "X-Plex-Token" = $plexToken }
    $playlistUri = "$plexServer/playlists"
    $playlistUri = "http://localhost:32400/playlists"  # For local testing
    Write-Host "Connecting to Plex server at $playlistUri..."
    $playlists = Invoke-RestMethod -Uri $playlistUri -Headers $headers

    $global:playlists = $playlists
    $playlist = $playlists.MediaContainer.Metadata | Where-Object { $_.title -eq $playlistTitle }
    if (-not $playlist) {
        Write-Error "Playlist '$playlistTitle' not found."
        return
    }

    $playlistId = $playlist.ratingKey
    $itemsUri = "$plexServer/playlists/$playlistId/items"
    $items = Invoke-RestMethod -Uri $itemsUri -Headers $headers

    # === EXTRACT ITEM IDs ===
    $itemIds = $items.MediaContainer.Metadata.ratingKey -join ","

    # === CREATE PLAYLIST FOR TARGET USER ===
    $createUri = "$plexServer/playlists?type=video&title=$playlistTitle&smart=0&uri=server://$($playlist.librarySectionID)/com.plexapp.plugins.library.library.item/$itemIds"
    $targetHeaders = @{ "X-Plex-Token" = $targetUserToken }

    Invoke-RestMethod -Method POST -Uri $createUri -Headers $targetHeaders
    Write-Host "Playlist '$playlistTitle' copied to target user."
}
#>
function Get-PlexServerToken {
    param (
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

 #   $Credential = New-PlexLogin -UserName $UserName -Credential $Credential

    # $targetUserToken = "TARGET_USER_TOKEN"  # Token for the user you're sharing with

    # Build Basic Auth header
    $plainAuth = "{0}:{1}" -f $Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Password
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($plainAuth))

    # Build headers
    $headers = @{
        'Authorization'            = "Basic $base64Auth"
        'X-Plex-Client-Identifier' = "PowerShell-Test"
        'X-Plex-Product'           = "PowerShell-Test"
        'X-Plex-Version'           = "V0.01"
        'X-Plex-Username'          = $UserName
        'Accept'                   = 'application/xml'
        'Content-Type'             = 'application/xml'    
    }

    # Send the request
    $response = Invoke-RestMethod -Uri "https://plex.tv/users/sign_in.xml" -Method POST -Headers $headers
    #    $response = Invoke-RestMethod -Uri "https://plex.tv/users/sign_in.json" -Method POST -Headers $headers

    # Extract token
    $plexToken = $response.user.authToken
    # Write-Host "✅ X-Plex-Token: $plexToken"
    return $plexToken
}
#>