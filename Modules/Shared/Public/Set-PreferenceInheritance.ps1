function Set-PreferenceInheritance {
    <#
    .SYNOPSIS
        Sets up preference inheritance for called functions to automatically pass through Verbose/Debug flags.
    .DESCRIPTION
        This function configures $PSDefaultParameterValues to automatically pass through the current
        Verbose and Debug preferences to specified functions. This eliminates the need for manual
        preference checking in each function and provides a clean way to ensure called functions
        respect the user's verbose/debug preferences.
    .PARAMETER Functions
        Array of function names that should inherit the current Verbose/Debug preferences.
        Can include wildcards for pattern matching.
    .PARAMETER Clear
        When specified, clears all preference inheritance settings.
    .EXAMPLE
        Set-PreferenceInheritance -Functions 'Write-Message', 'Get-Path', 'Start-ProgressActivity'
        Sets up inheritance for the specified functions to automatically receive Verbose/Debug flags.
    .EXAMPLE
        Set-PreferenceInheritance -Functions 'Write-Message*', 'Get-*'
        Sets up inheritance for all functions starting with 'Write-Message' and all functions starting with 'Get-'.
    .EXAMPLE
        Set-PreferenceInheritance -Clear
        Clears all preference inheritance settings.
    .NOTES
        This function should be called at the beginning of functions that want to ensure
        their called functions inherit Verbose/Debug preferences. It's much cleaner than
        manually checking preferences in each called function.
        The function automatically handles both Verbose and Debug preferences for each
        specified function.
    .LINK
        $PSDefaultParameterValues
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$Functions,
        [Parameter()]
        [switch]$Clear
    )
    if ($Clear) {
        # Clear all preference inheritance settings
        $keysToRemove = $PSDefaultParameterValues.Keys | Where-Object {
            $_ -match ':(Verbose|Debug)$'
        }
        foreach ($key in $keysToRemove) {
            $PSDefaultParameterValues.Remove($key)
        }
        Write-Message "Cleared all preference inheritance settings" -Type Verbose
        return
    }
    if (-not $Functions) {
        Write-Message "No functions specified. Use -Clear to remove all settings." -Type Warning
        return
    }
    foreach ($function in $Functions) {
        # Set Verbose preference inheritance
        $PSDefaultParameterValues["$function`:Verbose"] = $VerbosePreference
        # Set Debug preference inheritance
        $PSDefaultParameterValues["$function`:Debug"] = $DebugPreference
        Write-Message "Set preference inheritance for: $function" -Type Verbose
    }
}
