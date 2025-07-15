<#
.SYNOPSIS
    Uninstall script for the VideoUtility PowerShell module.

.DESCRIPTION
    This script removes the VideoUtility PowerShell module by unloading it from the current session.

.EXAMPLE
    .\Uninstall.ps1
    
    Removes the VideoUtility module from the current session.

.NOTES
    This script requires PowerShell 7.0 or higher.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)

#Requires -Version 7.0

# Remove the module if it's currently loaded
if (Get-Module -Name VideoUtility -ErrorAction SilentlyContinue) {
    Write-Verbose 'Removing loaded VideoUtility module'
    Remove-Module -Name VideoUtility -Force:$Force -ErrorAction SilentlyContinue
    if (-not $Quiet) {
        Write-Host 'VideoUtility module uninstalled successfully!' -ForegroundColor Green
    }
}
else {
    if (-not $Quiet) {
        Write-Warning 'VideoUtility module is not currently loaded'
    }
} 