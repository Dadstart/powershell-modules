# Verbose and Debug Flag Inheritance

This document explains how Verbose and Debug flags are properly inherited by called functions in the PowerShell modules using a clean, centralized approach.

## Overview

In PowerShell, when you call a function with `-Verbose` or `-Debug` flags, those preferences are stored in the `$VerbosePreference` and `$DebugPreference` variables. However, these variables are scoped, and child functions don't automatically inherit them unless they're explicitly designed to do so.

## The Problem

When you call functions like `Write-Message`, `Get-Path`, and `Start-ProgressActivity` from within your main functions (like `Export-SubtitleStream`), they don't automatically inherit the Verbose and Debug preferences from the calling function.

For example:
```powershell
# This should show verbose output from all called functions
Export-SubtitleStream -Source .\videos -Verbose
```

But without proper inheritance, only the main function would show verbose output, while the called functions would remain silent.

## The Clean Solution

Instead of cluttering each function with manual preference checks, we use PowerShell's `$PSDefaultParameterValues` to automatically pass through Verbose and Debug preferences to called functions.

### Set-PreferenceInheritance Function

The `Set-PreferenceInheritance` function provides a clean, centralized way to set up preference inheritance:

```powershell
# Set up inheritance for specific functions
Set-PreferenceInheritance -Functions 'Write-Message', 'Get-Path', 'Start-ProgressActivity'

# Clear all inheritance settings
Set-PreferenceInheritance -Clear
```

### How It Works

The function configures `$PSDefaultParameterValues` to automatically pass the current Verbose/Debug preferences to specified functions:

```powershell
# This automatically sets:
$PSDefaultParameterValues['Write-Message:Verbose'] = $VerbosePreference
$PSDefaultParameterValues['Write-Message:Debug'] = $DebugPreference
$PSDefaultParameterValues['Get-Path:Verbose'] = $VerbosePreference
# ... and so on
```

## Implementation in Functions

Functions that want to ensure their called functions inherit preferences simply call `Set-PreferenceInheritance` at the beginning:

```powershell
function Export-SubtitleStream {
    [CmdletBinding(SupportsShouldProcess)]
    param(...)

    begin {
        # Set up preference inheritance for called functions
        Set-PreferenceInheritance -Functions 'Write-Message', 'Get-Path', 'Start-ProgressActivity', 'Get-SubtitleStream'
        
        # ... rest of function
    }
}
```

## Testing

You can test the inheritance by running:

```powershell
# Test without verbose
Get-SubtitleStream -Source .\videos -Language eng | Export-SubtitleStream -OutputDirectory .\output

# Test with verbose - should show detailed output from all functions
Get-SubtitleStream -Source .\videos -Language eng -Verbose | Export-SubtitleStream -OutputDirectory .\output -Verbose

# Test with debug - should show debug output from all functions
Get-SubtitleStream -Source .\videos -Language eng -Debug | Export-SubtitleStream -OutputDirectory .\output -Debug
```

## Benefits

1. **Clean Code**: No manual preference checking cluttering the functions
2. **Centralized Management**: One function handles all preference inheritance
3. **Consistent Output**: All functions in the call chain respect the user's verbose/debug preferences
4. **Better Debugging**: Users can see detailed output from all functions when needed
5. **PowerShell Best Practices**: Uses PowerShell's built-in `$PSDefaultParameterValues` mechanism

## Functions That Support Inheritance

- ✅ `Write-Message` - Inherits Verbose and Debug preferences
- ✅ `Get-Path` - Inherits Verbose preference
- ✅ `Start-ProgressActivity` - Inherits Verbose preference
- ✅ `Get-SubtitleStream` - Inherits Verbose preference
- ✅ `Export-SubtitleStream` - Inherits Verbose and Debug preferences (via CmdletBinding)
- ✅ `Set-PreferenceInheritance` - Manages preference inheritance for other functions

## Usage Examples

### Basic Usage

```powershell
# In any function that calls other functions
begin {
    Set-PreferenceInheritance -Functions 'Write-Message', 'Get-Path', 'Start-ProgressActivity'
}
```

### Wildcard Support

```powershell
# Set inheritance for all functions starting with 'Get-'
Set-PreferenceInheritance -Functions 'Get-*'

# Set inheritance for all functions starting with 'Write-'
Set-PreferenceInheritance -Functions 'Write-*'
```

### Clearing Settings

```powershell
# Clear all preference inheritance settings
Set-PreferenceInheritance -Clear
```

## External Functions

Some functions like `Get-MediaStreams` and `Export-MediaStream` are from external modules and may not support preference inheritance. These functions will respect their own verbose/debug settings or the global preferences.

## Best Practices

1. Call `Set-PreferenceInheritance` at the beginning of functions that call other functions
2. Always use `-Verbose` when you want detailed output from all functions
3. Use `-Debug` when you need debugging information
4. Test your scripts with and without verbose flags to ensure proper output
5. Use wildcards when possible to reduce the number of function names to specify 