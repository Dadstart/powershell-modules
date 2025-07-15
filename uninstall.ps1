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
        
        # Check if module is loaded
        $LoadedModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
        
        if ($LoadedModule) {
            # Build remove parameters
            $RemoveParams = @{
                Name = $ModuleName
                Force = $Force
                ErrorAction = "Stop"
            }
            
            # Remove the module
            Remove-Module @RemoveParams
            
            $UninstalledModules += $ModuleName
            Write-UninstallMessage "Successfully uninstalled module: $ModuleName" "Info"
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