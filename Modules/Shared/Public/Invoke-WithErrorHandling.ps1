function Invoke-WithErrorHandling {
    <#
    .SYNOPSIS
        Executes a script block with standardized error handling.
    .DESCRIPTION
        Wraps a script block execution with consistent error handling that:
        - Catches and logs exceptions with descriptive messages
        - Provides stack trace information for debugging
        - Supports custom error messages and return values
        - Maintains consistent error reporting across modules
        This function standardizes the try-catch pattern used throughout
        the PowerShell modules to improve consistency and maintainability.
    .PARAMETER ScriptBlock
        The script block to execute within the error handling wrapper.
    .PARAMETER OperationName
        A descriptive name for the operation being performed.
        Used in error messages to provide context.
    .PARAMETER DefaultReturnValue
        The value to return if an error occurs and the operation should not throw.
        Default is $null.
    .PARAMETER ThrowOnError
        Whether to re-throw the exception after logging it.
        Default is $false (returns DefaultReturnValue instead).
    .PARAMETER ErrorEmoji
        Optional emoji to include in error messages for visual consistency.
        Default is "💥".
    .EXAMPLE
        $result = Invoke-WithErrorHandling -ScriptBlock { Get-Content "nonexistent.txt" } -OperationName "File reading"
        Attempts to read a file and returns $null if it fails, with proper error logging.
    .EXAMPLE
        $files = Invoke-WithErrorHandling -ScriptBlock { 
            Get-ChildItem -Path "C:\Source" -Filter "*.mkv" 
        } -OperationName "Video file discovery" -DefaultReturnValue @()
        Discovers video files and returns empty array if operation fails.
    .EXAMPLE
        Invoke-WithErrorHandling -ScriptBlock { 
            Copy-Item "source.txt" "dest.txt" -Force 
        } -OperationName "File copying" -ThrowOnError
        Copies a file and throws an exception if it fails, with proper error logging.
    .EXAMPLE
        $result = Invoke-WithErrorHandling -ScriptBlock { 
            Process-VideoFiles -Path "C:\Videos" 
        } -OperationName "Video processing" -ErrorEmoji "🎬" -DefaultReturnValue @()
        Processes video files with custom error emoji and returns empty array on failure.
    .OUTPUTS
        The result of the ScriptBlock execution, or DefaultReturnValue if an error occurs.
        If ThrowOnError is $true, exceptions are re-thrown after logging.
    .NOTES
        This function requires the ScratchCore module to be installed and available.
        Uses Write-Message for consistent logging across modules.
        Provides detailed error information for debugging while maintaining clean error handling.
        Supports both silent error handling (return default value) and explicit error handling (throw).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [scriptblock]$ScriptBlock,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OperationName,
        [Parameter()]
        [object]$DefaultReturnValue = $null,
        [Parameter()]
        [switch]$ThrowOnError,
        [Parameter()]
        [string]$ErrorEmoji = "💥"
    )
    try {
        return & $ScriptBlock
    }
    catch {
        $errorMessage = "$ErrorEmoji $OperationName failed: $($_.Exception.Message)"
        Write-Message $errorMessage -Type Error
        Write-Message "Stack trace: $($_.ScriptStackTrace)" -Type Verbose
        if ($ThrowOnError) {
            throw
        }
        return $DefaultReturnValue
    }
} 
