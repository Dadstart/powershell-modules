class PlexToolsConnection {
    <#
    .SYNOPSIS
        Represents Plex authentication credentials and server information.
    .DESCRIPTION
        The PlexToolsConnection class encapsulates all the information needed to authenticate
        with a Plex Media Server, including the server URL, username/password credentials,
        and authentication token.
    .PROPERTY Credential
        The PowerShell credential object containing username and password.
    .PROPERTY ServerUrl
        The URL of the Plex Media Server (e.g., "http://localhost:32400").
    .PROPERTY Token
        The Plex authentication token.
    .PROPERTY TimeoutSeconds
        The timeout value in seconds for API requests to the Plex server.
    .EXAMPLE
        $cred = [PlexToolsConnection]::new($psCredential, "http://localhost:32400", "token")
    .EXAMPLE
        $cred = Get-PlexToolsConnection
        $cred.ServerUrl
        $cred.Token
    #>
    hidden [pscredential]$Credential
    hidden [string]$ServerUrl
    hidden [string]$Token
    hidden [hashtable]$Headers
    [int]$TimeoutSeconds

    PlexToolsConnection([pscredential]$credential, [string]$serverUrl, [string]$token) {
        if (-not $credential) {
            throw [ArgumentNullException]::new('credential')
        }
        if (-not $token) {
            throw [ArgumentNullException]::new('token')
        }
        $this.Credential = $credential
        $this.ServerUrl = $serverUrl
        $this.Token = $token

        # Defaults
        $this.SetDefaultConfig()
    }

    [string]RefreshToken() {
        $this.Token = Get-PlexServerToken -Credential $this.Credential
        return $this.Token
    }

    [string]ToString() {
        return "PlexToolsConnection(ServerUrl='$($this.ServerUrl)', Username='$($this.Credential.UserName)'"
    }

    [hashtable]GetHeaders() {
        # Always return a clone so it can be modified without affecting the original
        return $this.Headers.Clone()
    }

    # Set the default configuration
    hidden [void]SetDefaultConfig() {
        $this.Headers = @{
            'Accept'                   = 'application/json'
            'X-Plex-Platform'          = 'Windows'
            'X-Plex-Platform-Version'  = '10'
            'X-Plex-Provides'          = 'controller'
            'X-Plex-Client-Identifier' = 'Dadstart PlexTools'
            'X-Plex-Product'           = 'Dadstart PlexTools'
            'X-Plex-Version'           = '0.0.1'
        }

        # Return default configuration if none exists
        $this.TimeoutSeconds = 30
    }
}
