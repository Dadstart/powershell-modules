# PowerShell Profile for PowerShell Modules Workspace
# This profile loads shared functions and modules for IntelliSense support
# Get the workspace root directory
$WorkspaceRoot = Split-Path $PROFILE -Parent
# Load shared functions for IntelliSense
$SharedPath = Join-Path $WorkspaceRoot 'Modules\Shared\Public'
if (Test-Path $SharedPath) {
    Get-ChildItem -Path $SharedPath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
    Write-Host "Loaded shared functions from: $SharedPath" -ForegroundColor Green
}
# Load modules for IntelliSense
$ModulesPath = Join-Path $WorkspaceRoot 'Modules'
if (Test-Path $ModulesPath) {
    Get-ChildItem -Path $ModulesPath -Directory | ForEach-Object {
        $ModulePath = Join-Path $_.FullName "$($_.Name).psd1"
        if (Test-Path $ModulePath) {
            try {
                Import-Module $ModulePath -Force -Global
                Write-Host "Loaded module: $($_.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to load module $($_.Name): $_" -ForegroundColor Yellow
            }
        }
    }
}
# Set up environment variables
$env:POWERSHELL_MODULES_WORKSPACE = $WorkspaceRoot
# Add workspace to PSModulePath for development
$CurrentPSModulePath = $env:PSModulePath
if ($CurrentPSModulePath -notlike "*$ModulesPath*") {
    $env:PSModulePath = "$ModulesPath;$CurrentPSModulePath"
}
Write-Host "PowerShell Modules Workspace profile loaded successfully!" -ForegroundColor Green
