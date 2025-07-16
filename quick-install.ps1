[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)
# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
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
Write-InstallMessage "Starting quick install (uninstall + install)..." "Info"
# Build parameters to pass to uninstall and install scripts
$ScriptParams = @{}
if ($Force) { $ScriptParams.Force = $true }
if ($Quiet) { $ScriptParams.Quiet = $true }
# Step 1: Uninstall all modules
Write-InstallMessage "Step 1: Uninstalling all modules..." "Info"
$UninstallScript = Join-Path $ScriptDir "uninstall.ps1"
if (Test-Path $UninstallScript) {
    try {
        & $UninstallScript @ScriptParams
        if ($LASTEXITCODE -ne 0) {
            Write-InstallMessage "Uninstall failed with exit code: $LASTEXITCODE" "Warning"
        }
        else {
            Write-InstallMessage "Uninstall completed successfully" "Info"
        }
    }
    catch {
        Write-InstallMessage "Error during uninstall: $($_.Exception.Message)" "Error"
    }
}
else {
    Write-InstallMessage "Uninstall script not found at: $UninstallScript" "Error"
    exit 1
}
# Step 2: Install all modules
Write-InstallMessage "Step 2: Installing all modules..." "Info"
$InstallScript = Join-Path $ScriptDir "install.ps1"
if (Test-Path $InstallScript) {
    try {
        & $InstallScript @ScriptParams
        if ($LASTEXITCODE -ne 0) {
            Write-InstallMessage "Install failed with exit code: $LASTEXITCODE" "Error"
            exit $LASTEXITCODE
        }
        else {
            Write-InstallMessage "Install completed successfully" "Info"
        }
    }
    catch {
        Write-InstallMessage "Error during install: $($_.Exception.Message)" "Error"
        exit 1
    }
}
else {
    Write-InstallMessage "Install script not found at: $InstallScript" "Error"
    exit 1
}
Set-WriteMessageConfig -IncludeContext
Write-InstallMessage "Quick install completed successfully!" "Info" 
