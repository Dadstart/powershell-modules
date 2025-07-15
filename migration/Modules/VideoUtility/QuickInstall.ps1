<#
.SYNOPSIS
    Quick install script for the VideoUtility PowerShell module.

.DESCRIPTION
    This script performs a quick installation of the VideoUtility PowerShell module.
    It removes any existing installation and installs the current version.

.EXAMPLE
    .\QuickInstall.ps1
    
    Performs a quick installation of the VideoUtility module.

.NOTES
    This script requires PowerShell 7.0 or higher.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)

#Requires -Version 7.0

if (-not $Quiet) {
    Write-Host 'Performing quick installation of VideoUtility module...' -ForegroundColor Yellow
}

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Run uninstall first to clean up any existing installation
$uninstallScript = Join-Path $scriptDir 'Uninstall.ps1'
if (Test-Path $uninstallScript) {
    Write-Verbose 'Running uninstall script to clean up existing installation'
    & $uninstallScript -Force:$Force -Quiet:$Quiet
}
else {
    Write-Error "Uninstall script not found: $uninstallScript"
    throw 'Uninstall script not found'
}

# Run install script
$installScript = Join-Path $scriptDir 'Install.ps1'
if (Test-Path $installScript) {
    Write-Verbose 'Running install script'
    & $installScript -Force:$Force -Quiet:$Quiet
}
else {
    Write-Error "Install script not found: $installScript"
    throw 'Install script not found'
}

if (-not $Quiet) {
    Write-Host 'Quick installation completed!' -ForegroundColor Green 
}