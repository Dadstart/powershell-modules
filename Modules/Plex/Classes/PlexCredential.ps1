class PlexCredential {
    <#
    .SYNOPSIS
        Represents Plex authentication credentials and server information.
    .DESCRIPTION
        The PlexCredential class encapsulates all the information needed to authenticate
        with a Plex Media Server, including the server URL, username/password credentials,
        and authentication token.
    .PROPERTY Credential
        The PowerShell credential object containing username and password.
    .PROPERTY ServerUrl
        The URL of the Plex Media Server (e.g., "http://localhost:32400").
    .PROPERTY Token
        The Plex authentication token.
    .EXAMPLE
        $cred = [PlexCredential]::new($psCredential, "http://localhost:32400", "token")
    .EXAMPLE
        $cred = Get-PlexCredential
        $cred.ServerUrl
        $cred.Token
    #>
    [pscredential]$Credential
    [string]$ServerUrl
    [string]$Token
    PlexCredential([pscredential]$credential, [string]$serverUrl, [string]$token) {
        if (-not $credential) {
            throw [ArgumentNullException]::new('credential')
        }
        if (-not $token) {
            throw [ArgumentNullException]::new('token')
        }
        $this.Credential = $credential
        $this.ServerUrl = $serverUrl
        $this.Token = $token
    }
    [string]RefreshToken() {
        $this.Token = Get-PlexServerToken -Credential $this.Credential
        return $this.Token
    }
    [string]ToString() {
        return "PlexCredential(ServerUrl='$($this.ServerUrl)', Username='$($this.Credential.UserName)'"
    }
}
