function Get-PlexServerToken {
    param (
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )
    # Build Basic Auth header
    $plainAuth = "{0}:{1}" -f $Credential.GetNetworkCredential().UserName, $Credential.GetNetworkCredential().Password
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($plainAuth))
    # Build headers
    $headers = @{
        'Authorization'            = "Basic $base64Auth"
        'X-Plex-Client-Identifier' = "PowerShell-Test"
        'X-Plex-Product'           = "PowerShell-Test"
        'X-Plex-Version'           = "V0.01"
        'X-Plex-Username'          = $Credential.UserName
        'Accept'                   = 'application/xml'
        'Content-Type'             = 'application/xml'    
    }
    # Send the request
    $response = Invoke-RestMethod -Uri "https://plex.tv/users/sign_in.xml" -Method POST -Headers $headers
    # Extract token
    $plexToken = $response.user.authToken
    return $plexToken
}
