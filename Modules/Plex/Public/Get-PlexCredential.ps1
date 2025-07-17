function Get-PlexCredential {
    <#
    .SYNOPSIS
        Prompts for Plex authentication credentials and returns a credential object.
    .DESCRIPTION
        Prompts the user for Plex server credentials using the standard Windows credential dialog.
        The function creates a PlexCredential object containing the server URL, username/password,
        and authentication token for use with other Plex module functions.
        If no ServerUrl is provided, the function uses the default localhost server URL
        (http://localhost:32400).
    .PARAMETER ServerUrl
        The URL of the Plex Media Server. If not provided, defaults to http://localhost:32400.
    .EXAMPLE
        Get-PlexCredential
        Prompts for credentials using the default localhost server URL.
    .EXAMPLE
        Get-PlexCredential -ServerUrl "http://192.168.1.100:32400"
        Prompts for credentials using the specified server URL.
    .OUTPUTS
        [PlexCredential] Object containing server URL, credentials, and authentication token.
    .NOTES
        This function uses the standard PowerShell credential retrieval for secure credential input.
        The returned PlexCredential object can be used with other Plex module functions
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
    begin {
        $config = Get-PlexToolsConfig
    }
    process {
        if ($ServerUrl) {
            $uri = [UriBuilder]::new($ServerUrl)
        }
        else {
            $uri = [UriBuilder]::new($config.DefaultServerProtocol, $config.DefaultServerHost, $config.DefaultServerPort)
        }
        $cred = Get-Credential -Message 'Enter your Plex credentials' -UserName $UserName
        $token = Get-PlexServerToken -Credential $cred
        return [PlexCredential]::new($cred, $uri.ToString(), $token)
    }
}