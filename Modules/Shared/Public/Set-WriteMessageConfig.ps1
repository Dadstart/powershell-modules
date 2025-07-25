function Set-WriteMessageConfig {
    <#
    .SYNOPSIS
        Configures global defaults for Write-Message function.
    .DESCRIPTION
        Set-WriteMessageConfig allows you to set global configuration options
        that will be used as defaults for all Write-Message calls unless overridden
        by individual parameters.
        This function provides a centralized way to configure logging behavior
        across your entire script or module without having to specify the same
        parameters repeatedly.
    .PARAMETER LogFile
        Path to a log file where all messages will be written. Set to $null to disable file logging.
    .PARAMETER TimeStamp
        When specified, adds timestamps to all messages by default.
    .PARAMETER Separator
        The default separator to use between message objects. Defaults to a space.
    .PARAMETER AsJson
        When specified, outputs all messages in JSON format by default.
    .PARAMETER LevelColors
        Hashtable mapping message types to colors. Valid colors: Black, DarkBlue, DarkGreen,
        DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan,
        Red, Magenta, Yellow, and White.
    .PARAMETER IncludeContext
        When specified, enables automatic call-site context for all messages. This will
        prefix each message with the script name and line number where Write-Message was called.
        Format: [ScriptName.ps1:LineNumber] Message
    .PARAMETER ForceAnsi
        When specified, forces the use of ANSI escape codes for colors, even if terminal
        support is not detected. Useful for CI/CD environments or when you know your
        terminal supports ANSI but it's not being detected automatically.
    .PARAMETER DisableAnsi
        When specified, disables ANSI escape codes and forces the use of PowerShell's
        native color support via Write-Host -ForegroundColor.
    .PARAMETER Reset
        When specified, resets all configuration to default values.
    .EXAMPLE
        # Enable file logging and timestamps globally
        Set-WriteMessageConfig -LogFile "C:\logs\app.log" -TimeStamp
        # Now all Write-Message calls will log to file with timestamps
        Write-Message "This will be logged" -Type Info
        Write-Message "This too" -Type Success
    .EXAMPLE
        # Configure custom colors
        Set-WriteMessageConfig -LevelColors @{
            'Info'       = 'Blue'
            'Success'    = 'Green'
            'Warning'    = 'Yellow'
            'Error'      = 'Red'
            'Processing' = 'Cyan'
            'Debug'      = 'Gray'
            'Verbose'    = 'Gray'
        }
    .EXAMPLE
        # Enable JSON output globally
        Set-WriteMessageConfig -AsJson
        # All messages will now output as JSON
        Write-Message "Processing started" -Type Info
        # Output: {"TimeStamp":"2024-01-01T12:00:00.0000000","Type":"Info","Message":"Processing started"}
    .EXAMPLE
        # Enable call-site context globally
        Set-WriteMessageConfig -IncludeContext
        # All messages will now include script name and line number
        Write-Message "Processing started" -Type Info
        # Output: [MyScript.ps1:42] Processing started
        Write-Message "Error occurred" -Type Error
        # Output: [MyScript.ps1:78] Error occurred
    .EXAMPLE
        # Enable call-site context and file logging
        Set-WriteMessageConfig -IncludeContext -LogFile "C:\logs\app.log"
        # Messages will be logged to file with context
        Write-Message "Processing video files..." -Type Processing
        # File content: [VideoProcessor.ps1:15] Processing video files...
    .EXAMPLE
        # Force ANSI escape codes for cross-platform compatibility
        Set-WriteMessageConfig -ForceAnsi
        # All messages will now use ANSI escape codes for colors
        Write-Message "Processing started" -Type Info
        Write-Message "Success!" -Type Success
    .EXAMPLE
        # Disable ANSI and use PowerShell native colors
        Set-WriteMessageConfig -DisableAnsi
        # All messages will use Write-Host -ForegroundColor
        Write-Message "Processing started" -Type Info
        Write-Message "Success!" -Type Success
    .EXAMPLE
        # Reset to defaults
        Set-WriteMessageConfig -Reset
    .OUTPUTS
        None. This function modifies the global WriteMessageConfig object.
    .LINK
        Write-Message
    #>
    [CmdletBinding(DefaultParameterSetName = 'Configure')]
    param(
        [Parameter(ParameterSetName = 'Configure')]
        [string]$LogFile,
        [Parameter(ParameterSetName = 'Configure')]
        [switch]$TimeStamp,
        [Parameter(ParameterSetName = 'Configure')]
        [object]$Separator,
        [Parameter(ParameterSetName = 'Configure')]
        [switch]$AsJson,
        [Parameter(ParameterSetName = 'Configure')]
        [hashtable]$LevelColors,
        [Parameter(ParameterSetName = 'Configure')]
        [switch]$IncludeContext,
        [Parameter(ParameterSetName = 'Configure')]
        [switch]$ForceAnsi,
        [Parameter(ParameterSetName = 'Configure')]
        [switch]$DisableAnsi,
        [Parameter(ParameterSetName = 'Reset')]
        [switch]$Reset
    )
    # Initialize config if it doesn't exist
    if (-not $script:WriteMessageConfig) {
        $script:WriteMessageConfig = Get-WriteMessageConfig -Default
    }
    if ($Reset) {
        # Reset to defaults
        $script:WriteMessageConfig = Get-WriteMessageConfig -Default
        Write-Verbose 'Write-Message configuration reset to defaults.'
        return
    }
    # Update configuration based on provided parameters
    if ($PSBoundParameters.ContainsKey('LogFile')) {
        $script:WriteMessageConfig.LogFile = $LogFile
        Write-Verbose "LogFile set to: $LogFile"
    }
    if ($PSBoundParameters.ContainsKey('TimeStamp')) {
        $script:WriteMessageConfig.TimeStamp = $TimeStamp.IsPresent
        Write-Verbose "TimeStamp set to: $($TimeStamp.IsPresent)"
    }
    if ($PSBoundParameters.ContainsKey('Separator')) {
        $script:WriteMessageConfig.Separator = $Separator
        Write-Verbose "Separator set to: $Separator"
    }
    if ($PSBoundParameters.ContainsKey('AsJson')) {
        $script:WriteMessageConfig.AsJson = $AsJson.IsPresent
        Write-Verbose "AsJson set to: $($AsJson.IsPresent)"
    }
    if ($PSBoundParameters.ContainsKey('IncludeContext')) {
        $script:WriteMessageConfig.IncludeContext = $IncludeContext.IsPresent
        Write-Verbose "IncludeContext set to: $($IncludeContext.IsPresent)"
    }
    if ($PSBoundParameters.ContainsKey('ForceAnsi')) {
        $script:WriteMessageConfig.ForceAnsi = $ForceAnsi.IsPresent
        $script:SupportsAnsi = $ForceAnsi.IsPresent
        Write-Verbose "ForceAnsi set to: $($ForceAnsi.IsPresent)"
    }
    if ($PSBoundParameters.ContainsKey('DisableAnsi')) {
        $script:WriteMessageConfig.DisableAnsi = $DisableAnsi.IsPresent
        $script:SupportsAnsi = -not $DisableAnsi.IsPresent
        Write-Verbose "DisableAnsi set to: $($DisableAnsi.IsPresent)"
    }
    if ($PSBoundParameters.ContainsKey('LevelColors')) {
        # Validate and update colors
        $validColors = @('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta',
            'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red',
            'Magenta', 'Yellow', 'White')
        foreach ($type in $LevelColors.Keys) {
            if ($LevelColors[$type] -in $validColors) {
                $script:WriteMessageConfig.LevelColors[$type] = $LevelColors[$type]
                Write-Verbose "Color for '$type' set to: $($LevelColors[$type])"
            }
            else {
                Write-Warning "Invalid color '$($LevelColors[$type])' for type '$type'. Valid colors: $($validColors -join ', ')"
            }
        }
    }
    Write-Verbose 'Write-Message configuration updated.'
}
