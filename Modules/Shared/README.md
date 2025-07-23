# Shared Module

A collection of common PowerShell utilities and helper functions used across all modules in this project.

## Overview

The Shared module provides essential utilities for:

- **Message formatting and logging** - Consistent output formatting across all modules
- **Error handling** - Standardized error handling patterns
- **File and path operations** - Common file system utilities
- **Progress tracking** - Activity progress indicators
- **Environment information** - System and environment utilities

## Requirements

- PowerShell 7.4 or higher
- No external dependencies

## Installation

This module is part of the larger PowerShell modules collection. Install the entire collection using:

```powershell
# Clone the repository
git clone https://github.com/Dadstart/powershell-modules.git

# Import the Shared module
Import-Module .\Modules\Shared\Shared.psd1
```

**Note**: You can also import the Shared module through any of the other modules (Git, Media, Plex, Rip) as they all export the Shared functions.

**Important**: To avoid duplicate function definitions, import only one module at a time, or import the Shared module separately if you need multiple modules.

## Functions

### Message and Logging

#### `Write-Message`

Centralized message formatting with consistent color coding and output streams.

```powershell
# Basic usage
Write-Message "Processing started" -Type Info
Write-Message "Operation completed" -Type Success
Write-Message "Warning message" -Type Warning
Write-Message "Error occurred" -Type Error

# With configuration
Set-WriteMessageConfig -TimeStamp -LogFile "C:\logs\app.log"
Write-Message "This will be logged with timestamp" -Type Info
```

#### `Set-WriteMessageConfig`

Configure global defaults for Write-Message function.

```powershell
# Enable timestamps and file logging
Set-WriteMessageConfig -TimeStamp -LogFile "C:\logs\app.log"

# Enable JSON output
Set-WriteMessageConfig -AsJson

# Enable call-site context
Set-WriteMessageConfig -IncludeContext
```

#### `Get-WriteMessageConfig`

Get current Write-Message configuration.

```powershell
$config = Get-WriteMessageConfig
$config.TimeStamp  # Check if timestamps are enabled
```

### Error Handling

#### `Invoke-WithErrorHandling`

Execute commands with standardized error handling.

```powershell
$result = Invoke-WithErrorHandling -ScriptBlock {
    # Your code here
    Get-Process -Name "notepad"
} -ErrorAction Continue
```

### File and Path Operations

#### `Get-Path`

Enhanced path resolution and validation utilities.

```powershell
# Resolve relative paths
$fullPath = Get-Path -Path ".\relative\path"

# Validate paths exist
if (Test-Path (Get-Path -Path "C:\some\path")) {
    Write-Message "Path exists" -Type Success
}
```

#### `Get-String`

Convert objects to string representation with consistent formatting.

```powershell
# Convert various object types to strings
$string = Get-String -Object @{ Name = "John"; Age = 30 }
$string = Get-String -Object @("Item1", "Item2") -Separator ", "
```

### Progress Tracking

#### `Start-ProgressActivity`

Create and manage progress indicators for long-running operations.

```powershell
$activity = Start-ProgressActivity -Name "Processing Files" -Total 100
foreach ($file in $files) {
    # Process file
    $activity.Increment()
}
$activity.Complete()
```

### Environment and System

#### `Get-EnvironmentInfo`

Get comprehensive system and environment information.

```powershell
$envInfo = Get-EnvironmentInfo
$envInfo.PowerShellVersion
$envInfo.OperatingSystem
$envInfo.Architecture
```

#### `New-ProcessingDirectory`

Create standardized processing directories with proper structure.

```powershell
$processingDir = New-ProcessingDirectory -BasePath "C:\temp" -Name "VideoProcessing"
```

### Utility Functions

#### `Set-PreferenceInheritance`

Manage PowerShell preference inheritance across scopes.

```powershell
Set-PreferenceInheritance -PreferenceName "ErrorActionPreference" -Value "Continue"
```

## Classes

### `ProgressActivity`

A class for managing progress indicators with methods for incrementing, updating, and completing progress tracking.

```powershell
$files = #...
$progress = Start-ProgressActivity -Activity "Processing files" -TotalItems $files.Count
$i = 0
foreach ($file in $files) {
    $i++
    $progress.Update(@{ CurrentItem = $i; Status = "Processing $file" })
}
$progress.Stop(@{ Status = "All files processed" })
```

## Configuration

The Shared module uses a configuration system for the `Write-Message` function:

- **TimeStamp**: Add timestamps to messages
- **LogFile**: Write messages to log files
- **AsJson**: Output messages in JSON format
- **IncludeContext**: Include call-site context in messages
- **LevelColors**: Customize colors for different message types

## Examples

### Basic Module Usage

```powershell
# Import the module
Import-Module .\Modules\Shared\Shared.psm1

# Configure message formatting
Set-WriteMessageConfig -TimeStamp -LogFile "C:\logs\myapp.log"

# Use throughout your scripts
Write-Message "Application started" -Type Info
Write-Message "Processing files..." -Type Processing

# Handle errors gracefully
$result = Invoke-WithErrorHandling -ScriptBlock {
    # Your code here
} -ErrorAction Continue

Write-Message "Application completed" -Type Success
```

### Advanced Usage

```powershell
# Create a progress activity
$progress = Start-ProgressActivity -Name "File Processing" -Total 1000

# Process with error handling and logging
foreach ($file in $files) {
    $result = Invoke-WithErrorHandling -ScriptBlock {
        Process-File -Path $file
    } -ErrorAction Continue

    if ($result.Success) {
        Write-Message "Processed: $file" -Type Success
    } else {
        Write-Message "Failed: $file - $($result.Error)" -Type Error
    }

    $progress.Increment()
}

$progress.Complete()
```

## Contributing

When adding new functions to the Shared module:

1. Follow the existing naming conventions
2. Include comprehensive help documentation
3. Add appropriate error handling
4. Write unit tests for new functions
5. Update this README with new function documentation

## License

This module is part of the PowerShell modules collection. See the main LICENSE file for details.

## Support

For issues and questions:

- GitHub Issues: <https://github.com/Dadstart/powershell-modules/issues>
- Documentation: See individual function help with `Get-Help <FunctionName>`
