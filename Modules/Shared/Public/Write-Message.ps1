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
        - Automatic call-site context (script name and line number)
        - ANSI escape code support for cross-platform terminal compatibility

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

    .PARAMETER IncludeContext
        When specified, includes call-site context (script name and line number) in the message.
        If not specified, uses global configuration.

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
        # Enable call-site context globally
        Set-WriteMessageConfig -IncludeContext

        # Messages will now include script name and line number
        Write-Message "Processing started" -Type Info
        # Output: [MyScript.ps1:42] Processing started

    .EXAMPLE
        # Enable call-site context for a specific message
        Write-Message "Error occurred" -Type Error -IncludeContext
        # Output: [MyScript.ps1:78] Error occurred

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

        ANSI Support:
        The function automatically detects terminal capabilities and uses ANSI escape codes
        for consistent cross-platform color rendering when supported.

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
        [string]$Color,

        [Parameter()]
        [switch]$IncludeContext
    )

    begin {
        # --- Initialize WriteMessageConfig if not exists ---
        if (-not $script:WriteMessageConfig) {
            $script:WriteMessageConfig = Get-WriteMessageConfig -Default
            <#
            $script:WriteMessageConfig = [PSCustomObject]@{
                LogFile        = $null
                TimeStamp      = $false
                Separator      = ' '
                AsJson         = $false
                IncludeContext = $false  # Whether to include call-site context
                ForceAnsi      = $false  # Force ANSI escape codes
                DisableAnsi    = $false  # Disable ANSI escape codes
                LevelColors    = @{
                    'Info'       = 'White'
                    'Success'    = 'Green'
                    'Warning'    = 'Yellow'
                    'Error'      = 'Red'
                    'Processing' = 'Cyan'
                    'Debug'      = 'Gray'
                    'Verbose'    = 'Gray'
                    'Default'    = 'White'
                }
            #>
        }

        # --- ANSI Color Mapping (Bright Colors) ---
        $script:AnsiColors = @{
            'Red'         = '91'
            'Green'       = '92'
            'Yellow'      = '93'
            'Blue'        = '94'
            'Magenta'     = '95'
            'Cyan'        = '96'
            'Gray'        = '90'
            'White'       = '97'
            'Black'       = '30'
            'DarkBlue'    = '34'
            'DarkGreen'   = '32'
            'DarkCyan'    = '36'
            'DarkRed'     = '31'
            'DarkMagenta' = '35'
            'DarkYellow'  = '33'
            'DarkGray'    = '90'
        }

        # --- Terminal Detection for ANSI Support ---
        if (-not (Test-Path Variable:script:AnsiSupportChecked)) {
            $script:AnsiSupportChecked = $true

            # Check if ANSI is disabled in config
            if ($script:WriteMessageConfig.DisableAnsi) {
                $script:SupportsAnsi = $false
            }
            # Check if ANSI is forced in config
            elseif ($script:WriteMessageConfig.ForceAnsi) {
                $script:SupportsAnsi = $true
            }
            else {
                # Auto-detect terminal support for ANSI escape codes
                $script:SupportsAnsi = $Host.UI.SupportsVirtualTerminal -or 
                $env:TERM -or 
                $env:COLORTERM -or
                ($env:OS -eq 'Windows_NT' -and $Host.UI.RawUI.WindowSize.Width -gt 0)

                # Additional check for PowerShell 6+ on Windows
                if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows) {
                    $script:SupportsAnsi = $true
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

        $effectiveIncludeContext = if ($PSBoundParameters.ContainsKey('IncludeContext')) {
            $IncludeContext.IsPresent
        }
        else {
            $script:WriteMessageConfig.IncludeContext
        }

        # --- Determine effective color ---
        $effectiveColor = if ($PSBoundParameters.ContainsKey('Color')) {
            $Color
        }
        else {
            $script:WriteMessageConfig.LevelColors[$Type]
        }

        # --- Validate color and fallback to default if invalid ---
        $validColors = @(
            'Black',
            'DarkBlue',
            'DarkGreen',
            'DarkCyan',
            'DarkRed',
            'DarkMagenta',
            'DarkYellow',
            'Gray',
            'DarkGray',
            'Blue',
            'Green',
            'Cyan',
            'Red',
            'Magenta',
            'Yellow',
            'White'
        )

        if ($effectiveColor -notin $validColors) {
            Write-Warning "Invalid color '$effectiveColor'. Falling back to default color for type '$Type'."
            $effectiveColor = $script:WriteMessageConfig.LevelColors[$Type]
        }

        # --- Format each message argument ---
        $blocks = @()
        foreach ($item in $Object) {
            $blocks += Get-String -Object $item -Separator $effectiveSep
        }
        $text = $blocks -join $effectiveSep

        # --- Prepare context for JSON output ---
        $ctx = $null
        if ($effectiveIncludeContext) {
            $inv = $PSCmdlet.MyInvocation
            $scriptName = [IO.Path]::GetFileName($inv.ScriptName)
            $lineNumber = $inv.ScriptLineNumber
            $ctx = '{0}:{1}' -f $scriptName, $lineNumber
        }

        # --- Structured output mode ---
        if ($effectiveAsJson) {
            $entry = [PSCustomObject]@{
                TimeStamp = (Get-Date).ToString('o')
                Type      = $Type
                Message   = $text
                Context   = $ctx
            }
            $entry | ConvertTo-Json -Depth 5
            return
        }

        # --- Prepare text for regular output ---
        if ($effectiveTimeStamp) {
            $text = ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $text)
        }

        # --- Add call-site context if enabled ---
        if ($effectiveIncludeContext) {
            $text = '[{0}] {1}' -f $ctx, $text
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
                # Use ANSI codes or Write-Host with color for Info, Success, Processing
                if ($script:SupportsAnsi -and $effectiveColor -in $script:AnsiColors.Keys) {
                    # Use ANSI escape codes for cross-platform compatibility
                    $ansiCode = $script:AnsiColors[$effectiveColor]
                    $coloredText = "`e[${ansiCode}m$text`e[0m"

                    if ($NoNewline) {
                        Write-Host -Object $coloredText -NoNewline
                    }
                    else {
                        Write-Host -Object $coloredText
                    }
                }
                else {
                    # Fallback to PowerShell colors
                    if ($NoNewline) {
                        Write-Host -Object $text -ForegroundColor $effectiveColor -NoNewline
                    }
                    else {
                        Write-Host -Object $text -ForegroundColor $effectiveColor
                    }
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