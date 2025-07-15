# Windows PowerShell Commands Guide

This guide provides Windows-compatible commands for running code validation and following PowerShell best practices.

## Quick Start Commands

### 1. Run Basic Validation
```cmd
# Using batch file (easiest)
run-validation.bat

# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File .\scripts\powershell\Run-Validation-Windows.ps1
```

### 2. Run Detailed Validation
```cmd
# Using batch file
run-validation.bat "" Detailed

# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File .\scripts\powershell\Run-Validation-Windows.ps1 -Detailed
```

### 3. Validate Specific Module
```cmd
# Using batch file
run-validation.bat ScratchCore Detailed

# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File .\scripts\powershell\Run-Validation-Windows.ps1 -ModuleName ScratchCore -Detailed
```

### 4. Install Required Tools
```cmd
# Using batch file
run-validation.bat "" "" InstallTools
$$
# Using PowerShell directly
powershell -ExecutionPolicy Bypass -File .\scripts\powershell\Run-Validation-Windows.ps1 -InstallTools
```

## PowerShell Execution Policy

Before running scripts, you may need to set the execution policy:

```powershell
# Check current policy
Get-ExecutionPolicy

# Set policy for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Set policy for all users (requires admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

## Module Management Commands

### Import Modules
```powershell
# Import ScratchCore module
Import-Module .\modules\ScratchCore\ScratchCore.psm1 -Force

# Import all modules
Get-ChildItem .\modules -Directory | ForEach-Object { Import-Module $_.FullName -Force }
```

### Check Module Status
```powershell
# List loaded modules
Get-Module

# Check specific module
Get-Module ScratchCore

# Test module manifest
Test-ModuleManifest .\modules\ScratchCore\ScratchCore.psd1
```

## Code Quality Tools

### PSScriptAnalyzer
```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# Run analysis on all modules
Invoke-ScriptAnalyzer -Path .\modules -Recurse

# Run with custom settings
Invoke-ScriptAnalyzer -Path .\modules -Settings .\config\PSScriptAnalyzerSettings.psd1 -Recurse

# Run on specific module
Invoke-ScriptAnalyzer -Path .\modules\ScratchCore -Recurse
```

### Pester Testing
```powershell
# Install Pester
Install-Module -Name Pester -Force -Scope CurrentUser

# Run all tests
Invoke-Pester -Path .\modules\ScratchCore\Tests

# Run tests with output
Invoke-Pester -Path .\modules\ScratchCore\Tests -Output Detailed

# Run tests and generate report
Invoke-Pester -Path .\modules\ScratchCore\Tests -OutputFile .\test-results.xml -OutputFormat NUnitXml
```

## Development Workflow Commands

### 1. Setup Development Environment
```powershell
# Install required tools
Install-Module -Name PSScriptAnalyzer, Pester -Force -Scope CurrentUser

# Import modules
Import-Module .\modules\ScratchCore\ScratchCore.psm1 -Force

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Daily Development Commands
```powershell
# Quick validation
.\scripts\powershell\Run-Validation-Windows.ps1 -ModuleName ScratchCore

# Run tests
Invoke-Pester -Path .\modules\ScratchCore\Tests

# Check code style
Invoke-ScriptAnalyzer -Path .\modules\ScratchCore -Recurse
```

### 3. Pre-Commit Validation
```powershell
# Full validation
.\scripts\powershell\Run-Validation-Windows.ps1 -Detailed

# Run all tests
Get-ChildItem .\modules -Directory | ForEach-Object { 
    $testPath = Join-Path $_.FullName "Tests"
    if (Test-Path $testPath) {
        Write-Host "Running tests for $($_.Name)..." -ForegroundColor Cyan
        Invoke-Pester -Path $testPath
    }
}
```

## Windows-Specific Considerations

### Path Handling
```powershell
# Use Join-Path for cross-platform compatibility
$path = Join-Path $PSScriptRoot "modules"

# Use [System.IO.Path] for advanced operations
$absolutePath = [System.IO.Path]::GetFullPath("relative\path")

# Use Get-Path function (project-specific)
$resolvedPath = Get-Path -Path "relative\path" -PathType Absolute
```

### File Operations
```powershell
# Create directories
New-Item -ItemType Directory -Path ".\new\folder" -Force

# Copy files with progress
Copy-Item -Path "source.txt" -Destination "target.txt" -Force

# Remove items safely
Remove-Item -Path ".\temp" -Recurse -Force -ErrorAction SilentlyContinue
```

### Error Handling
```powershell
# Use try-catch blocks
try {
    $result = Get-Content -Path "file.txt" -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Message "File not found: $($_.Exception.Message)" -Type Error
}
catch {
    Write-Message "Unexpected error: $($_.Exception.Message)" -Type Error
}
```

## Performance Commands

### Measure Execution Time
```powershell
# Measure command execution
Measure-Command { Get-ChildItem -Path .\modules -Recurse }

# Profile function performance
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Get-Path -Path "test\path" -PathType Absolute
$stopwatch.Stop()
Write-Host "Execution time: $($stopwatch.ElapsedMilliseconds)ms"
```

### Memory Usage
```powershell
# Check PowerShell memory usage
Get-Process -Name powershell | Select-Object ProcessName, WorkingSet, VirtualMemorySize

# Force garbage collection
[System.GC]::Collect()
```

## Troubleshooting Commands

### Check PowerShell Version
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check .NET version
[System.Environment]::Version
```

### Check Module Dependencies
```powershell
# List all loaded modules
Get-Module | Format-Table Name, Version, Path

# Check module requirements
Get-Module -Name ScratchCore | Select-Object -ExpandProperty RequiredModules
```

### Debug Module Loading
```powershell
# Import with verbose output
Import-Module .\modules\ScratchCore\ScratchCore.psm1 -Force -Verbose

# Check module exports
(Get-Module ScratchCore).ExportedCommands.Keys
```

## Batch File Examples

### Create Custom Batch Files
```batch
@echo off
REM Example: validate-scratchcore.bat
echo Running ScratchCore validation...
powershell -ExecutionPolicy Bypass -File .\scripts\powershell\Run-Validation-Windows.ps1 -ModuleName ScratchCore -Detailed
pause
```

### Run Multiple Validations
```batch
@echo off
REM Example: validate-all.bat
echo Running validation for all modules...
powershell -ExecutionPolicy Bypass -File .\scripts\powershell\Run-Validation-Windows.ps1 -Detailed
echo.
echo Running Pester tests...
powershell -Command "Invoke-Pester -Path .\modules -Recurse"
pause
```

## Command Prompt Shortcuts

### Create Shortcuts
```cmd
REM Create shortcut for validation
echo powershell -ExecutionPolicy Bypass -File "%~dp0scripts\powershell\Run-Validation-Windows.ps1" > validate.bat

REM Create shortcut for testing
echo powershell -Command "Invoke-Pester -Path .\modules\ScratchCore\Tests" > test-scratchcore.bat
```

### Environment Variables
```cmd
REM Set project path
set PROJECT_ROOT=C:\scratch

REM Add to PATH (temporary)
set PATH=%PATH%;%PROJECT_ROOT%\scripts\powershell

REM Use in commands
powershell -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\scripts\powershell\Run-Validation-Windows.ps1"
```

## Best Practices Summary

### 1. Always Use Proper Paths
```powershell
# Good
$path = Join-Path $PSScriptRoot "modules"

# Bad
$path = ".\modules"
```

### 2. Handle Errors Gracefully
```powershell
# Good
try {
    $result = Get-Content -Path $filePath -ErrorAction Stop
}
catch {
    Write-Message "Error reading file: $($_.Exception.Message)" -Type Error
}

# Bad
$result = Get-Content -Path $filePath
```

### 3. Use Project-Specific Functions
```powershell
# Good
Write-Message "Processing..." -Type Processing

# Bad
Write-Host "Processing..."
```

### 4. Validate Inputs
```powershell
# Good
[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[string]$Path

# Bad
[string]$Path
```

## Quick Reference

| Task | Command |
|------|---------|
| Run validation | `run-validation.bat` |
| Run detailed validation | `run-validation.bat "" Detailed` |
| Validate specific module | `run-validation.bat ScratchCore` |
| Install tools | `run-validation.bat "" "" InstallTools` |
| Run PSScriptAnalyzer | `Invoke-ScriptAnalyzer -Path .\modules -Recurse` |
| Run Pester tests | `Invoke-Pester -Path .\modules\ScratchCore\Tests` |
| Import module | `Import-Module .\modules\ScratchCore\ScratchCore.psm1 -Force` |
| Check execution policy | `Get-ExecutionPolicy` |
| Set execution policy | `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` |

## Support

If you encounter issues:

1. Check PowerShell version: `$PSVersionTable.PSVersion`
2. Verify execution policy: `Get-ExecutionPolicy`
3. Check module availability: `Get-Module -ListAvailable`
4. Review error messages and follow troubleshooting steps
5. Ensure all required tools are installed

For more detailed information, see the main [PowerShell Best Practices Guide](PowerShell-Best-Practices.md). 