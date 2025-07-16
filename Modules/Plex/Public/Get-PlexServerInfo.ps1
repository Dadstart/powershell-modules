function Get-PlexServerInfo {
    <#
    .SYNOPSIS
        Retrieves detailed information about a Plex Media Server.
    .DESCRIPTION
        Gets comprehensive information about a Plex Media Server including version,
        server name, platform, and other system details. This function provides
        detailed server information that can be useful for diagnostics and monitoring.
    .PARAMETER Credential
        The Plex credential object containing server URL and authentication token.
    .PARAMETER TimeoutSec
        The timeout in seconds for the request. Defaults to 30.
    .EXAMPLE
        $cred = Get-PlexCredential
        Get-PlexServerInfo -Credential $cred
        Gets server information using credentials.
    .OUTPUTS
        [PSCustomObject] Object containing server information including version, name, platform, etc.
    .NOTES
        This function provides detailed server information that can be useful for
        system administration and troubleshooting.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PlexCredential is a custom type containing PSCredential, not plain text')]
    param(
        [Parameter(Mandatory = $true)]
        [PlexCredential]$Credential,
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    try {
        Write-Message "Retrieving server information from: $($Credential.ServerUrl)" -Type Processing
        # Make the request using relative path
        $response = Invoke-PlexApiRequest -Uri $Script:PlexApiEndpoints.ServerInfo -Credential $Credential -TimeoutSec $TimeoutSec
        if ($response -and $response.MediaContainer) {
            $serverInfo = $response.MediaContainer
            # Create a custom object with server information
            $result = [PSCustomObject]@{
                ServerUrl = $Credential.ServerUrl
                FriendlyName = $serverInfo.friendlyName
                MachineIdentifier = $serverInfo.machineIdentifier
                Version = $serverInfo.version
                Platform = $serverInfo.platform
                PlatformVersion = $serverInfo.platformVersion
                Product = $serverInfo.product
                ProductVersion = $serverInfo.productVersion
                MyPlexUsername = $serverInfo.myPlexUsername
                MyPlexMappingState = $serverInfo.myPlexMappingState
                MyPlexSigninState = $serverInfo.myPlexSigninState
                MyPlexSubscription = $serverInfo.myPlexSubscription
                TranscoderActiveVideoSessions = $serverInfo.transcoderActiveVideoSessions
                TranscoderAudio = $serverInfo.transcoderAudio
                TranscoderLyrics = $serverInfo.transcoderLyrics
                TranscoderPhoto = $serverInfo.transcoderPhoto
                TranscoderSubtitles = $serverInfo.transcoderSubtitles
                TranscoderVideo = $serverInfo.transcoderVideo
                TranscoderVideoBitrates = $serverInfo.transcoderVideoBitrates
                TranscoderVideoQualities = $serverInfo.transcoderVideoQualities
                TranscoderVideoResolutions = $serverInfo.transcoderVideoResolutions
                UpdatedAt = $serverInfo.updatedAt
                Size = $serverInfo.size
            }
            Write-Message "✅ Successfully retrieved server information" -Type Success
            Write-Message "Server: $($result.FriendlyName) (v$($result.Version))" -Type Info
            return $result
        }
        else {
            Write-Message "❌ Failed to retrieve server information - invalid response format" -Type Error
            return $null
        }
    }
    catch {
        Write-Message "❌ Failed to retrieve server information: $($_.Exception.Message)" -Type Error
        throw
    }
} 
