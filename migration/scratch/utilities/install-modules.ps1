[CmdletBinding()]
param(
    [switch]$ShowFunctions,
    [switch]$SkipExternalModules,
    [switch]$Quiet,
    [switch]$Force
)

$installedModules = @()

if (-not $SkipExternalModules) {
    if (-not $Quiet) {
        Write-Host 'Installing VideoUtility module' -ForegroundColor Cyan
    }
    & 'C:\repos\video-utilities\PowerShell\VideoUtility\QuickInstall.ps1' -Force:$Force -Quiet:$Quiet
    $installedModules += 'VideoUtility'

    if (-not (Get-Module 'VideoUtility')) {
        Write-Error 'VideoUtility module not installed'
        return
    }
}

Write-Verbose "VideoUtility module path: $((Get-Module 'VideoUtility').Path)"

# Get the script directory (repository root)
Push-Location $PSScriptRoot
$repoRoot = (git rev-parse --show-toplevel)
Pop-Location

Write-Verbose "Installing PowerShell modules from repository: $repoRoot"

$modulesRoot = Join-Path $repoRoot 'modules'
if (-not (Test-Path $modulesRoot)) {
    Write-Error "Module Root '$modulesRoot' not found"
    return
}

$allModules = @('ScratchCore', 'Video', 'DVD', 'GitTools', 'Plex')

# Remove modules that are already loaded
foreach ($moduleName in $allModules) {
    $moduleRoot = Join-Path $modulesRoot $moduleName
    # Check if module is already loaded
    $isAlreadyLoaded = $null -ne (Get-Module -Name $moduleName -ErrorAction SilentlyContinue)
    if ($isAlreadyLoaded) {
        if (-not $Force) {
            Write-Host "Module $moduleName is already loaded. Use -Force to reinstall." -ForegroundColor Yellow
            $installedModules += $moduleName
            continue
        }
        else {        
            if (-not $Quiet) {
                Write-Host "Removing $moduleName module"
            }
            Remove-Module -Name $moduleName -Force | Out-Null
        }
    }
}

foreach ($moduleName in $allModules) {
    try {        
        $moduleRoot = Join-Path $modulesRoot $moduleName
        if (-not $Quiet) {
            Write-Host "Installing $moduleName module from $moduleRoot" -ForegroundColor Cyan
        }

        Import-Module $moduleRoot -Force:$Force

        Write-Verbose "Checking if $moduleName module is installed"
        if (Get-Module -Name $moduleName) {
            if (-not $Quiet) {
                Write-Host "✅ $moduleName module installed successfully!" -ForegroundColor Green
            }
            $installedModules += $moduleName

            # Show available functions - only if needed
            if ($ShowFunctions) {
                $functions = Get-Command -Module $moduleName
        
                if (-not $Quiet -and $functions) {
                    Write-Host "$moduleName available functions:"
                    $functions | ForEach-Object { Write-Host "  - $($_.Name)" }
                }
            }
            continue
        }
        else {
            Write-Error "$moduleName module not installed"
            continue
        }
    }
    catch {
        Write-Error "Failed to install one or more modules: $($_.Exception.Message)"
        # Continue with other modules even if one fails
    }
}


if ($installedModules.Count -gt 0) {
    Write-Host "`nSuccessfully installed modules: $($installedModules -join ', ')" -ForegroundColor Green
}
else {
    Write-Error 'No modules were installed successfully.' -ForegroundColor Red
} 