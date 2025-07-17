function Set-PlexToolsConfig {
    <#
    .SYNOPSIS
        Configures global defaults for Plex server connections.
    .DESCRIPTION
        Set-PlexToolsConfig allows you to set global configuration options
        that will be used as defaults for all Plex server connections unless overridden
        by individual parameters.
        This function provides a centralized way to configure Plex server behavior
        across your entire script or module without having to specify the same
        connection parameters repeatedly.
    .PARAMETER ServerProtocol
        The default protocol to use for Plex server connections (http or https).
        Defaults to 'http'.
    .PARAMETER ServerPort
        The default port to use for Plex server connections.
        Defaults to 32400.
    .PARAMETER ServerHost
        The default server URL to use for Plex server connections.
        Defaults to 'http://localhost:32400'.
    .PARAMETER ServerTimeout
        The default timeout in seconds for Plex API requests.
        Defaults to 30.
    .PARAMETER ServerHeaders
        Custom HTTP headers to include with all Plex API requests.
        This should be a hashtable of header name-value pairs.
    .PARAMETER Reset
        When specified, resets all configuration to default values.
    .EXAMPLE
        # Set custom server URL and timeout
        Set-PlexToolsConfig -ServerHost "http://192.168.1.100:32400" -ServerTimeout 60
        # Now all Plex functions will use these defaults unless overridden
        Get-PlexLibraries -Credential $cred
    .EXAMPLE
        # Configure custom HTTP headers
        Set-PlexToolsConfig -ServerHeaders @{
            'X-Custom-Header' = 'CustomValue'
            'User-Agent' = 'MyPlexClient/1.0'
        }
    .EXAMPLE
        # Set secure connection defaults
        Set-PlexToolsConfig -ServerProtocol "https" -ServerPort 32443
    .EXAMPLE
        # Reset to defaults
        Set-PlexToolsConfig -Reset
    .OUTPUTS
        None. This function modifies the global PlexToolsConfig object.
    .LINK
        Get-PlexToolsConfig
        Get-PlexCredential
    #>
    [CmdletBinding(DefaultParameterSetName = 'Configure')]
    param(
        [Parameter(ParameterSetName = 'Configure')]
        [string]$ServerProtocol,
        [Parameter(ParameterSetName = 'Configure')]
        [string]$ServerPort,
        [Parameter(ParameterSetName = 'Configure')]
        [string]$ServerHost,
        [Parameter(ParameterSetName = 'Configure')]
        [string]$ServerTimeout,
        [Parameter(ParameterSetName = 'Configure')]
        [string]$ServerHeaders,
        [Parameter(ParameterSetName = 'Reset')]
        [switch]$Reset
    )
    # Initialize config if it doesn't exist
    if (-not $script:PlexToolsConfig) {
        $script:PlexToolsConfig = Get-PlexToolsConfig -Default
    }

    if ($Reset) {
        # Reset to defaults
        $script:PlexToolsConfig = Get-PlexToolsConfig -Default
        Write-Verbose 'Write-Message configuration reset to defaults.'
        return
    }

    if ($PSBoundParameters.ContainsKey('ServerProtocol')) {
        $script:PlexToolsConfig.ServerProtocol = $ServerProtocol
        Write-Verbose "ServerProtocol set to: $ServerProtocol"
    }
    if ($PSBoundParameters.ContainsKey('ServerPort')) {
        $script:PlexToolsConfig.ServerPort = $ServerPort
        Write-Verbose "ServerPort set to: $ServerPort"
    }
    if ($PSBoundParameters.ContainsKey('ServerHost')) {
        $script:PlexToolsConfig.ServerHost = $ServerHost
        Write-Verbose "ServerHost set to: $ServerHost"
    }
    if ($PSBoundParameters.ContainsKey('ServerTimeout')) {
        $script:PlexToolsConfig.ServerTimeout = $ServerTimeout
        Write-Verbose "ServerTimeout set to: $ServerTimeout"
    }
    if ($PSBoundParameters.ContainsKey('ServerHeaders')) {
        $script:PlexToolsConfig.ServerHeaders = $ServerHeaders
        Write-Verbose "ServerHeaders set to: $ServerHeaders"
    }
    Write-Verbose 'PlexTools configuration updated.'
}
