[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Quiet
)

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to write messages based on Quiet switch
function Write-QuickInstallMessage {
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

Write-QuickInstallMessage "Starting quick install (uninstall + install)..." "Info"

# Build parameters to pass to uninstall and install scripts
$ScriptParams = @{}
if ($Force) { $ScriptParams.Force = $true }
if ($Quiet) { $ScriptParams.Quiet = $true }

# Step 1: Uninstall all modules
Write-QuickInstallMessage "Step 1: Uninstalling all modules..." "Info"
$UninstallScript = Join-Path $ScriptDir "uninstall.ps1"

if (Test-Path $UninstallScript) {
    try {
        & $UninstallScript @ScriptParams
        if ($LASTEXITCODE -ne 0) {
            Write-QuickInstallMessage "Uninstall failed with exit code: $LASTEXITCODE" "Warning"
        }
        else {
            Write-QuickInstallMessage "Uninstall completed successfully" "Info"
        }
    }
    catch {
        Write-QuickInstallMessage "Error during uninstall: $($_.Exception.Message)" "Error"
    }
}
else {
    Write-QuickInstallMessage "Uninstall script not found at: $UninstallScript" "Error"
    exit 1
}

# Step 2: Install all modules
Write-QuickInstallMessage "Step 2: Installing all modules..." "Info"
$InstallScript = Join-Path $ScriptDir "install.ps1"

if (Test-Path $InstallScript) {
    try {
        & $InstallScript @ScriptParams
        if ($LASTEXITCODE -ne 0) {
            Write-QuickInstallMessage "Install failed with exit code: $LASTEXITCODE" "Error"
            exit $LASTEXITCODE
        }
        else {
            Write-QuickInstallMessage "Install completed successfully" "Info"
        }
    }
    catch {
        Write-QuickInstallMessage "Error during install: $($_.Exception.Message)" "Error"
        exit 1
    }
}
else {
    Write-QuickInstallMessage "Install script not found at: $InstallScript" "Error"
    exit 1
}

Write-QuickInstallMessage "Quick install completed successfully!" "Info" 