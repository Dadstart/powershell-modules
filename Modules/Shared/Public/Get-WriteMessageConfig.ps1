function Get-WriteMessageConfig {
    <#
    .SYNOPSIS
        Gets the current Write-Message configuration.

    .DESCRIPTION
        Get-WriteMessageConfig returns the current global configuration
        for the Write-Message function, showing all default settings.

    .EXAMPLE
        Get-WriteMessageConfig

        Returns the current configuration object with all settings.

    .OUTPUTS
        PSCustomObject containing the current WriteMessageConfig settings.

    .LINK
        Write-Message
        Set-WriteMessageConfig
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Default
    )

    if ($Default -or (-not $script:WriteMessageConfig)) {
        # Return default configuration if none exists
        return [PSCustomObject]@{
            LogFile        = $null
            TimeStamp      = $false
            Separator      = ' '
            AsJson         = $false
            IncludeContext = $false
            ForceAnsi      = $false
            DisableAnsi    = $false
            LevelColors    = @{
                'Info'       = 'White'
                'Success'    = 'Green'
                'Warning'    = 'Yellow'
                'Error'      = 'Red'
                'Processing' = 'Cyan'
                'Debug'      = 'Gray'
                'Verbose'    = 'Gray'
                'Default'    = 'Gray'
            }
        }
    }

    return $script:WriteMessageConfig
}
