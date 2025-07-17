function Test-PlexConnection {
    <#
    .SYNOPSIS
        Tests the connection to a Plex Media Server.
    .DESCRIPTION
        Tests connectivity to a Plex Media Server by making a request to the server info endpoint.
        This function can be used to verify that the Plex server is accessible and responding
        before making other API calls.
    .PARAMETER Credential
        The Plex credential object containing server URL and authentication token.
    .PARAMETER TimeoutSec
        The timeout in seconds for the connection test. Defaults to 30.
    .EXAMPLE
        $cred = Get-PlexCredential
        Test-PlexConnection -Credential $cred
        Tests connectivity to a Plex server using credentials.
    .OUTPUTS
        [bool] True if the connection is successful, False otherwise.
    .NOTES
        This function provides a quick way to verify Plex server connectivity
        before attempting more complex operations.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PlexCredential is a custom type containing PSCredential, not plain text')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Credential,
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    try {
        Write-Message "Testing connection to Plex server: $($Credential.ServerUrl)" -Type Processing
        # Make the test request using relative path
        $response = Invoke-PlexApiRequest -Uri '/' -Credential $Credential -TimeoutSec $TimeoutSec
        if ($response) {
            Write-Message "✅ Successfully connected to Plex server" -Type Success
            Write-Message "Server version: $($response.MediaContainer.version)" -Type Verbose
            Write-Message "Server name: $($response.MediaContainer.friendlyName)" -Type Verbose
            return $true
        }
        else {
            Write-Message "❌ Failed to connect to Plex server - no response received" -Type Error
            return $false
        }
    }
    catch {
        Write-Message "❌ Failed to connect to Plex server: $($_.Exception.Message)" -Type Error
        return $false
    }
} 
