function Write-Message {
    <#
    .SYNOPSIS
        Provides standardized output formatting with consistent color coding across all modules.

    .DESCRIPTION
        Write-Message centralizes all output formatting to ensure consistency
        across the DVD, Video, GitTools, and ScratchCore modules. This function provides
        a unified interface for all types of output with appropriate color coding.

        The function supports:
        - Different output types (Info, Success, Warning, Error, Processing, Debug, Verbose)
        - Consistent color coding for each type
        - Proper PowerShell stream usage (Debug, Verbose, Warning, Error)
        - Optional no-newline output for progress indicators
        - Global configuration for default settings

        Color Scheme:
        - Success: Green - Completion messages, successful operations
        - Processing: Cyan - Active processing, current operations
        - Warning: Yellow - Warnings, non-critical issues
        - Error: Red - Errors, critical failures
        - Info: White - General information, neutral messages
        - Debug/Verbose: Gray - Detailed debugging information

    .PARAMETER Object
        The message to output. Can include emojis and formatting. Supports $null values,
        which will be converted to an empty string, similar to Write-Host behavior.

    .PARAMETER Type
        The type of output, which determines the color and stream used.

        - Info: White text via Write-Host (general information)
        - Success: Green text via Write-Host (completion messages)
        - Warning: Text via Write-Warning (warnings)
        - Error: Text via Write-Error (errors)
        - Processing: Cyan text via Write-Host (active operations)
        - Debug: Text via Write-Debug (debugging information)
        - Verbose: Text via Write-Verbose (detailed information)

    .PARAMETER NoNewline
        When specified, suppresses the newline character. Useful for progress indicators
        or when building multi-part messages.

    .PARAMETER Separator
        The separator to use between objects. Defaults to a space.

    .PARAMETER LogFile
        Path to log file for writing messages. If not specified, uses global configuration.

    .PARAMETER TimeStamp
        When specified, adds timestamp to messages. If not specified, uses global configuration.

    .PARAMETER AsJson
        When specified, outputs messages in JSON format. If not specified, uses global configuration.

    .PARAMETER Color
        Override the default color for the specified Type. If not specified, uses default colors.

    .EXAMPLE
        Write-Message "Processing video files..." -Type Processing

        Outputs: "Processing video files..." in cyan color

    .EXAMPLE
        Write-Message "Successfully converted 5 files" -Type Success

        Outputs: "Successfully converted 5 files" in green color

    .EXAMPLE
        Write-Message "⚠️ Found 3 files but need 5 episodes" -Type Warning

        Outputs: "⚠️ Found 3 files but need 5 episodes" in yellow color

    .EXAMPLE
        Write-Message "🚫 No valid files found" -Type Error

        Outputs: "🚫 No valid files found" in red color

    .EXAMPLE
        Write-Message "Found 15 files in directory" -Type Verbose

        Outputs: "Found 15 files in directory" via Write-Verbose (gray when verbose enabled)

    .EXAMPLE
        Write-Message "Processing..." -Type Info -NoNewline
        Write-Message " Done!" -Type Success

        Outputs: "Processing... Done!" on the same line with different colors

    .EXAMPLE
        # Configure global defaults
        Set-WriteMessageConfig -LogFile "C:\logs\app.log" -TimeStamp -AsJson

        # Use global configuration
        Write-Message "This will be logged with timestamp and JSON format"

    .OUTPUTS
        None. This function outputs to the appropriate PowerShell stream.

        The function automatically handles the appropriate PowerShell stream
        based on the Type parameter:
        - Debug and Verbose types use their respective streams
        - Warning and Error types use their respective streams
        - Other types use Write-Host with appropriate colors

        Color coding helps users quickly identify message types:
        - Green = Success/Completion
        - Cyan = Active Processing
        - Yellow = Warnings
        - Red = Errors
        - White = General Info
        - Gray = Debug/Verbose (when enabled)

    .LINK
        Write-Host
        Write-Verbose
        Write-Debug
        Write-Warning
        Write-Error
        Set-WriteMessageConfig
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments, Position = 0)]
        [AllowNull()]
        [Alias('Message', 'Msg')]
        [object[]]$Object,

        [Parameter()]
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Processing', 'Debug', 'Verbose')]
        [string]$Type = 'Info',

        [Parameter()]
        [switch]$NoNewline,

        [Parameter()]
        [object]$Separator,

        [Parameter()]
        [string]$LogFile,

        [Parameter()]
        [switch]$TimeStamp,

        [Parameter()]
        [switch]$AsJson,

        [Parameter()]
        [string]$Color
    )

    begin {
        # --- Initialize WriteMessageConfig if not exists ---
        if (-not $script:WriteMessageConfig) {
            $script:WriteMessageConfig = [PSCustomObject]@{
                LogFile     = $null
                TimeStamp   = $false
                Separator   = ' '
                AsJson      = $false
                LevelColors = @{
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

        # --- Resolve effective values from parameters or config ---
        $effectiveLogFile = if ($PSBoundParameters.ContainsKey('LogFile')) {
            $LogFile
        }
        else {
            $script:WriteMessageConfig.LogFile
        }

        $effectiveTimeStamp = if ($PSBoundParameters.ContainsKey('TimeStamp')) {
            $TimeStamp.IsPresent
        }
        else {
            $script:WriteMessageConfig.TimeStamp
        }

        $effectiveSep = if ($PSBoundParameters.ContainsKey('Separator')) {
            $Separator
        }
        else {
            $script:WriteMessageConfig.Separator
        }

        $effectiveAsJson = if ($PSBoundParameters.ContainsKey('AsJson')) {
            $AsJson.IsPresent
        }
        else {
            $script:WriteMessageConfig.AsJson
        }

        # --- Determine effective color ---
        $effectiveColor = if ($PSBoundParameters.ContainsKey('Color')) {
            $Color
        }
        else {
            $script:WriteMessageConfig.LevelColors[$Type]
        }

        # --- Format each message argument ---
        $blocks = @()
        foreach ($item in $Object) {
            $blocks += Get-String -Object $item -Separator $effectiveSep
        }
        $text = $blocks -join $effectiveSep
        
        if ($effectiveTimeStamp) {
            $text = ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $text)
        }

        # --- Structured output mode ---
        if ($effectiveAsJson) {
            $entry = [PSCustomObject]@{
                TimeStamp = (Get-Date).ToString('o')
                Type      = $Type
                Message   = $text
            }
            $entry | ConvertTo-Json -Depth 5
            return
        }
    }
    process {
        # Route to appropriate PowerShell stream based on type
        switch ($Type) {
            'Debug' {
                # Check multiple scopes to find the debug preference from the original caller
                $callerDebugPreference = $DebugPreference
                for ($scope = 1; $scope -le 10; $scope++) {
                    try {
                        $scopeDebugPreference = (Get-Variable `
                                -Name DebugPreference `
                                -Scope $scope `
                                -ErrorAction SilentlyContinue).Value
                        if ($scopeDebugPreference -ne 'SilentlyContinue') {
                            $callerDebugPreference = $scopeDebugPreference
                            break
                        }
                    }
                    catch {
                        # If we can't access this scope, try the next one
                        continue
                    }
                }

                if ($callerDebugPreference -ne 'SilentlyContinue') {
                    Write-Debug $text
                }
            }
            'Verbose' {
                # Check multiple scopes to find the verbose preference from the original caller
                $callerVerbosePreference = $VerbosePreference
                for ($scope = 1; $scope -le 10; $scope++) {
                    try {
                        $scopeVerbosePreference = (Get-Variable `
                                -Name VerbosePreference `
                                -Scope $scope `
                                -ErrorAction SilentlyContinue).Value
                        if ($scopeVerbosePreference -ne 'SilentlyContinue') {
                            $callerVerbosePreference = $scopeVerbosePreference
                            break
                        }
                    }
                    catch {
                        # If we can't access this scope, try the next one
                        continue
                    }
                }

                if ($callerVerbosePreference -ne 'SilentlyContinue') {
                    Write-Verbose $text
                }
            }
            'Warning' {
                Write-Warning $text
            }
            'Error' {
                Write-Error $text
            }
            default {
                # Use Write-Host with color for Info, Success, Processing
                if ($NoNewline) {
                    Write-Host -Object $text -ForegroundColor $effectiveColor -NoNewline
                }
                else {
                    Write-Host -Object $text -ForegroundColor $effectiveColor
                }
                if ($effectiveLogFile) {
                    Add-Content -Path $effectiveLogFile -Value $text
                }
            }
        }
    }
    end {
    }
}

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
        Red, Magenta, Yellow, White.

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

        [Parameter(ParameterSetName = 'Reset')]
        [switch]$Reset
    )

    # Initialize config if it doesn't exist
    if (-not $script:WriteMessageConfig) {
        $script:WriteMessageConfig = Get-WriteMessageConfig
    }

    if ($Reset) {
        # Reset to defaults
        $script:WriteMessageConfig = Get-WriteMessageConfig
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
    param()

    if (-not $script:WriteMessageConfig) {
        # Return default configuration if none exists
        return [PSCustomObject]@{
            LogFile     = $null
            TimeStamp   = $false
            Separator   = ' '
            AsJson      = $false
            LevelColors = @{
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