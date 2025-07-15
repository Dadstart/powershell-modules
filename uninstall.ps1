[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $ScriptDir "Modules"

# Define the modules to uninstall (excluding Shared as it's a dependency module)
$ModulesToUninstall = @(
    "Git",
    "Media", 
    "Plex",
    "Rip"
)

# Function to write messages based on Quiet switch
function Write-UninstallMessage {
    param([string]$Message, [string]$Type = "Info")
    
    switch ($Type) {
        "Info" { 
            if (-not $Quiet) {
                Write-Host $Message -ForegroundColor Cyan 
            }
        }
        "Warning" { Write-Warning $Message }
        "Error" { Write-Error $Message }
        "Verbose" { Write-Verbose $Message }
        "Summary" { Write-Host $Message -ForegroundColor Green }
    }
}

Write-UninstallMessage "Starting module uninstallation..." "Info"

$UninstalledModules = @()
$FailedModules = @()

foreach ($ModuleName in $ModulesToUninstall) {
    try {
        Write-UninstallMessage "Uninstalling module: $ModuleName" "Verbose"
        
        # Check if module is loaded (try both folder name and actual module name)
        $LoadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        if (-not $LoadedModule) {
            # Try to find the module by checking what's actually loaded from this path
            $ModulePath = Join-Path $ModulesPath $ModuleName
            if (Test-Path $ModulePath) {
                $ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"
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
                ErrorAction = "Stop"
            }
            
            # Remove the module
            Remove-Module @RemoveParams
            
            $UninstalledModules += $LoadedModule.Name
            Write-UninstallMessage "Successfully uninstalled module: $($LoadedModule.Name)" "Info"
        }
        else {
            Write-UninstallMessage "Module $ModuleName is not currently loaded" "Verbose"
            $UninstalledModules += $ModuleName
        }
    }
    catch {
        Write-UninstallMessage "Failed to uninstall module $ModuleName`: $($_.Exception.Message)" "Error"
        $FailedModules += $ModuleName
    }
}

# Summary
Write-UninstallMessage "`nUninstallation Summary:" "Info"
Write-UninstallMessage "Successfully uninstalled: $($UninstalledModules.Count) modules" "Info"

if ($UninstalledModules.Count -gt 0) {
    Write-UninstallMessage "Uninstalled modules: $($UninstalledModules -join ', ')" "Summary"
}

if ($FailedModules.Count -gt 0) {
    Write-UninstallMessage "Failed to uninstall: $($FailedModules.Count) modules" "Warning"
    Write-UninstallMessage "Failed modules: $($FailedModules -join ', ')" "Warning"
    exit 1
}

Write-UninstallMessage "All modules uninstalled successfully!" "Info" 