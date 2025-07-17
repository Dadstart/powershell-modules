function Get-PlexToolsConfig {
    <#
    .SYNOPSIS
        Gets the current Plex server configuration settings.
    .DESCRIPTION
        Get-PlexToolsConfig returns the current global configuration
        for Plex server connections, including default server settings,
        timeout values, and HTTP headers used for API requests.
        This function provides access to the centralized configuration
        that controls how the Plex module connects to Plex Media Servers.
    .PARAMETER Default
        When specified, returns the default configuration settings
        regardless of any custom settings that may have been applied.
    .EXAMPLE
        Get-PlexToolsConfig
        Returns the current configuration object with all Plex server settings.
    .EXAMPLE
        Get-PlexToolsConfig -Default
        Returns the default configuration settings, ignoring any custom changes.
    .OUTPUTS
        PSCustomObject containing the current Plex server configuration settings.
    .LINK
        Set-PlexToolsConfig
        Get-PlexCredential
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Default
    )
    if ($Default -or (-not $script:PlexToolsConfig)) {
        $headers = @{
            'Accept'                   = 'application/json'
            'X-Plex-Platform'          = 'Windows'
            'X-Plex-Platform-Version'  = '10'
            'X-Plex-Provides'          = 'controller'
            'X-Plex-Client-Identifier' = 'Dadstart PlexTools'
            'X-Plex-Product'           = 'Dadstart PlexTools'
            'X-Plex-Version'           = '0.0.1'
        }

        # Return default configuration if none exists
        return [PSCustomObject]@{
            DefaultServerProtocol = 'http'
            DefaultServerPort     = 32400
            DefaultServerHost      = 'http://localhost:32400'
            DefaultTimeout        = 30
            DefaultHeaders        = $headers
        }
    }
    return $script:PlexToolsConfig
}
