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
    
    .OUTPUTS
        None. This function outputs to the appropriate PowerShell stream.
    
    .NOTES
        This function is part of the refactoring effort to standardize output
        across all PowerShell modules. It replaces direct calls to Write-Host,
        Write-Warning, Write-Error, Write-Verbose, and Write-Debug with a
        consistent interface.
        
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
        [object]$Separator = ' '
    )

    # Convert object to string
    $message = Get-String -Object $Object -Separator $Separator
    $message = $message ?? [string]::Empty

    # Route to appropriate PowerShell stream based on type
    switch ($Type) {
        'Debug' { 
            # Check multiple scopes to find the debug preference from the original caller
            $callerDebugPreference = $DebugPreference
            for ($scope = 1; $scope -le 10; $scope++) {
                try {
                    $scopeDebugPreference = (Get-Variable -Name DebugPreference -Scope $scope -ErrorAction SilentlyContinue).Value
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
                Write-Debug $message
            }
        }
        'Verbose' { 
            # Check multiple scopes to find the verbose preference from the original caller
            $callerVerbosePreference = $VerbosePreference
            for ($scope = 1; $scope -le 10; $scope++) {
                try {
                    $scopeVerbosePreference = (Get-Variable -Name VerbosePreference -Scope $scope -ErrorAction SilentlyContinue).Value
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
                Write-Verbose $message
            }
        }
        'Warning' { 
            Write-Warning $message
        }
        'Error' { 
            Write-Error $message
        }
        default { 
            # Define color mapping for Write-Host output types
            $colors = @{
                'Info'       = 'White'
                'Success'    = 'Green'
                'Processing' = 'Cyan'
            }
            
            # Use Write-Host with color for Info, Success, Processing
            if ($NoNewline) {
                Write-Host -Object $message -ForegroundColor $colors[$Type] -NoNewline
            }
            else {
                Write-Host -Object $message -ForegroundColor $colors[$Type]
            }
        }
    }
} 