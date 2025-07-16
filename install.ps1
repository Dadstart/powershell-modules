[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)

# Function to write messages based on Quiet switch
function Write-InstallMessage {
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

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesPath = Join-Path $ScriptDir "Modules"
Write-InstallMessage "Modules path: $ModulesPath" "Verbose"

# Define the modules to install (excluding Shared as it's a dependency module)
$ModulesToInstall = @(
    "Git",
    "Media", 
    "Plex",
    "Rip"
)

Write-InstallMessage "Starting module installation..." "Info"

# Check if modules directory exists
if (-not (Test-Path $ModulesPath)) {
    Write-InstallMessage "Modules directory not found at: $ModulesPath" "Error"
    exit 1
}

$InstalledModules = @()
$FailedModules = @()

foreach ($ModuleName in $ModulesToInstall) {
    $ModulePath = Join-Path $ModulesPath $ModuleName
    Write-InstallMessage "Module path: $ModulePath" "Verbose"

    if (-not (Test-Path $ModulePath)) {
        Write-InstallMessage "Module directory not found: $ModulePath" "Warning"
        $FailedModules += $ModuleName
        continue
    }

    $ManifestPath = Join-Path $ModulePath "$ModuleName`Tools.psm1"
    Write-InstallMessage "Manifest path: $ManifestPath" "Verbose"
    if (-not (Test-Path $ManifestPath)) {
        Write-InstallMessage "Module manifest not found: $ManifestPath" "Warning"
        $FailedModules += $ModuleName
        continue
    }
    
    try {
        Write-InstallMessage "Installing module: $ModuleName" "Verbose"
        
        # Build import parameters
        $ImportParams = @{
            Name = $ManifestPath
            Force = $Force
            ErrorAction = "Stop"
        }
        
        # Import the module
        $ImportedModule = Import-Module @ImportParams -PassThru
        
        # Use the actual module name from the manifest, or fall back to folder name
        $ActualModuleName = if ($ImportedModule) { $ImportedModule.Name } else { $ModuleName }
        $InstalledModules += $ActualModuleName
        Write-InstallMessage "Successfully installed module: $ActualModuleName" "Info"
    }
    catch {
        Write-InstallMessage "Failed to install module $ModuleName`: $($_.Exception.Message)" "Error"
        $FailedModules += $ModuleName
    }
}

# Summary
Write-InstallMessage "`nInstallation Summary:" "Info"
Write-InstallMessage "Successfully installed: $($InstalledModules.Count) modules" "Info"

if ($InstalledModules.Count -gt 0) {
    Write-InstallMessage "Installed modules: $($InstalledModules -join ', ')" "Summary"
}

if ($FailedModules.Count -gt 0) {
    Write-InstallMessage "Failed to install: $($FailedModules.Count) modules" "Warning"
    Write-InstallMessage "Failed modules: $($FailedModules -join ', ')" "Warning"
    exit 1
}

Write-InstallMessage "All modules installed successfully!" "Info" 