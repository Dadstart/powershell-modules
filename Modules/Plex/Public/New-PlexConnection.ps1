function New-PlexConnection {
    <#
    .SYNOPSIS
        Creates a new Plex connection, prompts for authentication credentials and returns a connection object.
    .DESCRIPTION
        Prompts the user for Plex server credentials using the standard Windows credential dialog.
        The function creates a PlexToolsConnection object containing the server URL, username/password,
        and authentication token for use with other Plex module functions.
    .PARAMETER ServerUrl
        The URL of the Plex Media Server. If not provided, defaults to http://localhost:32400.
    .EXAMPLE
        New-PlexConnection
        Prompts for credentials using the default localhost server URL.
    .EXAMPLE
        New-PlexConnection -ServerUrl "http://192.168.1.100:32400"
        Prompts for credentials using the specified server URL.
    .OUTPUTS
        [PlexToolsConnection] Object containing server URL, credentials, and authentication token.
    .NOTES
        This function uses the standard PowerShell credential retrieval for secure credential input.
        The returned PlexToolsConnection object can be used with other Plex module functions
        that require authentication.
        The function automatically generates an authentication token from the provided
        credentials using the Plex server's authentication endpoint.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ServerUrl,
        [Parameter()]
        [string]$UserName
    )
    if (-not $ServerUrl) {
        $ServerUrl = 'http://localhost:32400'
    }
    $params = @{
        Message = 'Enter your Plex credentials'
    }
    if ($UserName) {
        $params.UserName = $UserName
    }

    $cred = Get-Credential @params
    $token = Get-PlexServerToken -Credential $cred
    return [PlexToolsConnection]::new($cred, $ServerUrl, $token)
}
