[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)
# Function to write messages based on Quiet switch
function Write-InstallMessage {
    param([string]$Message, [string]$Type = 'Info')
    switch ($Type) {
        'Info' {
            if (-not $Quiet) {
                Write-Host $Message -ForegroundColor Cyan 
            }
        }
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
        'Verbose' { Write-Verbose $Message }
        'Summary' { Write-Host $Message -ForegroundColor Green }
    }
}
# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $ScriptDir 'Modules'
Write-InstallMessage "Modules path: $ModulesPath" 'Verbose'
# Define the modules to uninstall (excluding Shared as it's a dependency module)
$ModulesToUninstall = @(
    'GitTools',
    'MediaTools',
    'NewMediaTools',
    'PlexTools',
    'RipTools'
)
Write-InstallMessage 'Starting module uninstallation...' 'Info'
$UninstalledModules = @()
$FailedModules = @()
foreach ($ModuleName in $ModulesToUninstall) {
    try {
        Write-InstallMessage "Uninstalling module: $ModuleName" 'Verbose'
        # Check if module is loaded (try both folder name and actual module name)
        $LoadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        if (-not $LoadedModule) {
            # Try to find the module by checking what's actually loaded from this path
            $ModulePath = Join-Path $ModulesPath $ModuleName
            if (Test-Path $ModulePath) {
                $ManifestPath = Join-Path $ModulePath "$ModuleName`Tools.psd1"
                if (Test-Path $ManifestPath) {
                    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
                    if ($Manifest.ModuleName) {
                        $LoadedModule = Get-Module -Name $Manifest.ModuleName -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        if ($LoadedModule) {
            # Build remove parameters
            $RemoveParams = @{
                Name = $LoadedModule.Name
                Force = $Force
                ErrorAction = 'Stop'
            }
            # Remove the module
            Remove-Module @RemoveParams
            $UninstalledModules += $LoadedModule.Name
            Write-InstallMessage "Successfully uninstalled module: $($LoadedModule.Name)" 'Info'
        }
        else {
            Write-InstallMessage "Module $ModuleName is not currently loaded" 'Verbose'
            $UninstalledModules += $ModuleName
        }
    }
    catch {
        Write-InstallMessage "Failed to uninstall module $ModuleName`: $($_.Exception.Message)" 'Error'
        $FailedModules += $ModuleName
    }
}
# Summary
Write-InstallMessage "`nUninstallation Summary:" 'Info'
Write-InstallMessage "Successfully uninstalled: $($UninstalledModules.Count) modules" 'Info'
if ($UninstalledModules.Count -gt 0) {
    Write-InstallMessage "Uninstalled modules: $($UninstalledModules -join ', ')" 'Summary'
}
if ($FailedModules.Count -gt 0) {
    Write-InstallMessage "Failed to uninstall: $($FailedModules.Count) modules" 'Warning'
    Write-InstallMessage "Failed modules: $($FailedModules -join ', ')" 'Warning'
    exit 1
}
Write-InstallMessage 'All modules uninstalled successfully!' 'Info'
