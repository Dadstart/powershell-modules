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
        if ($effectiveIncludeContext) {
            $inv = $PSCmdlet.MyInvocation
            $scriptName = [IO.Path]::GetFileName($inv.ScriptName)
            if ($scriptName) {
                $lineNumber = $inv.ScriptLineNumber
                $ctx = '{0}:{1}' -f $scriptName, $lineNumber
            }
            else {
                $ctx = '?'
            }
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
        # Log to file first
        if ($effectiveLogFile) {
            Add-Content -Path $effectiveLogFile -Value $text
        }

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
            }
        }
    }
    end {
    }
}
