<#
.SYNOPSIS
    Windows PowerShell script to run code validation with proper Windows commands.

.DESCRIPTION
    This script provides Windows-compatible commands to validate PowerShell code quality.
    It includes proper path handling and Windows-specific considerations.

.EXAMPLE
    .\Run-Validation-Windows.ps1

    Runs validation on all modules using Windows-compatible paths.

.EXAMPLE
    .\Run-Validation-Windows.ps1 -ModuleName "ScratchCore" -Detailed

    Runs detailed validation on the ScratchCore module only.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ModuleName,

    [Parameter()]
    [switch]$Detailed,

    [Parameter()]
    [switch]$FixIssues,

    [Parameter()]
    [switch]$InstallTools
)

# Set execution policy for current session (if needed)
if ($InstallTools) {
    Write-Host "🔧 Installing required tools..." -ForegroundColor Cyan
    
    # Install PSScriptAnalyzer if not present
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    }
    
    # Install Pester if not present
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Host "Installing Pester..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -Scope CurrentUser
    }
    
    Write-Host "✅ Tools installation complete!" -ForegroundColor Green
}

# Get the script directory and project root
$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$projectRoot = Split-Path $scriptDir -Parent | Split-Path -Parent

# Set working directory to project root
Set-Location $projectRoot

Write-Host "📁 Working Directory: $projectRoot" -ForegroundColor Cyan

# Import required modules using Windows paths
$modulesPath = Join-Path $projectRoot "modules"
$scriptsPath = Join-Path $projectRoot "scripts\powershell"

# Import ScratchCore module
$scratchCorePath = Join-Path $modulesPath "ScratchCore\ScratchCore.psm1"
if (Test-Path $scratchCorePath) {
    Import-Module $scratchCorePath -Force
    Write-Host "✅ ScratchCore module loaded" -ForegroundColor Green
}
else {
    Write-Host "❌ ScratchCore module not found at: $scratchCorePath" -ForegroundColor Red
    exit 1
}

# Import validation function
$validationScriptPath = Join-Path $scriptsPath "Validate-CodeQuality.ps1"
if (Test-Path $validationScriptPath) {
    . $validationScriptPath
    Write-Host "✅ Validation script loaded" -ForegroundColor Green
}
else {
    Write-Host "❌ Validation script not found at: $validationScriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n🚀 Starting PowerShell Code Quality Validation" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Run validation based on parameters
try {
    if ($ModuleName) {
        Write-Host "`n🔍 Validating module: $ModuleName" -ForegroundColor Cyan
        $results = Validate-CodeQuality -Path $modulesPath -ModuleName $ModuleName -Detailed:$Detailed -FixIssues:$FixIssues
    }
    else {
        Write-Host "`n🔍 Validating all modules" -ForegroundColor Cyan
        $results = Validate-CodeQuality -Path $modulesPath -Detailed:$Detailed -FixIssues:$FixIssues
    }
}
catch {
    Write-Host "❌ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Additional Windows-specific analysis
Write-Host "`n🪟 Windows-Specific Analysis" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

# Check for Windows-specific issues
$windowsIssues = @()

# Check for hardcoded paths
$hardcodedPaths = Get-ChildItem -Path $modulesPath -Recurse -Filter "*.ps1" | 
    Select-String -Pattern "C:\\|D:\\|E:\\" | 
    Where-Object { $_.Line -notmatch "#" } | 
    Select-Object -First 5

if ($hardcodedPaths) {
    Write-Host "⚠️  Found hardcoded Windows paths:" -ForegroundColor Yellow
    foreach ($path in $hardcodedPaths) {
        Write-Host "   • $($path.Filename):$($path.LineNumber) - $($path.Line.Trim())" -ForegroundColor Yellow
    }
}

# Check for Windows-specific commands
$windowsCommands = Get-ChildItem -Path $modulesPath -Recurse -Filter "*.ps1" | 
    Select-String -Pattern "Get-WmiObject|Get-CimInstance" | 
    Select-Object -First 3

if ($windowsCommands) {
    Write-Host "⚠️  Found Windows-specific commands:" -ForegroundColor Yellow
    foreach ($cmd in $windowsCommands) {
        Write-Host "   • $($cmd.Filename):$($cmd.LineNumber) - $($cmd.Line.Trim())" -ForegroundColor Yellow
    }
}

# Check for proper path separators
$pathSeparatorIssues = Get-ChildItem -Path $modulesPath -Recurse -Filter "*.ps1" | 
    Select-String -Pattern "\\\\" | 
    Where-Object { $_.Line -notmatch "\\\\(?!\\)" } | 
    Select-Object -First 3

if ($pathSeparatorIssues) {
    Write-Host "⚠️  Found potential path separator issues:" -ForegroundColor Yellow
    foreach ($issue in $pathSeparatorIssues) {
        Write-Host "   • $($issue.Filename):$($issue.LineNumber) - $($issue.Line.Trim())" -ForegroundColor Yellow
    }
}

# Performance recommendations for Windows
Write-Host "`n⚡ Windows Performance Recommendations:" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$moduleCount = $results.ModuleResults.Count
if ($moduleCount -gt 3) {
    Write-Host "• Consider using Import-Module with -Force for faster loading" -ForegroundColor White
}

$largeFunctions = ($results.ModuleResults | ForEach-Object { $_.Functions } | Where-Object { $_.Issues -contains "lines exceed 120 characters" }).Count
if ($largeFunctions -gt 0) {
    Write-Host "• Large functions may impact PowerShell ISE performance" -ForegroundColor White
}

# Security recommendations for Windows
Write-Host "`n🔒 Windows Security Recommendations:" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

Write-Host "• Ensure execution policy allows script execution" -ForegroundColor White
Write-Host "• Consider code signing for production deployment" -ForegroundColor White
Write-Host "• Use Windows Defender exclusions for development folders" -ForegroundColor White

# Export results with Windows-friendly path
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = Join-Path $projectRoot "validation-results-$timestamp.json"

try {
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`n💾 Results exported to: $resultsFile" -ForegroundColor Green
}
catch {
    Write-Host "`n⚠️  Failed to export results: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Summary with Windows context
Write-Host "`n🎯 Windows Validation Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host "Overall Score: $($results.OverallScore)/100" -ForegroundColor $(if ($results.OverallScore -ge 80) { 'Green' } elseif ($results.OverallScore -ge 60) { 'Yellow' } else { 'Red' })
Write-Host "Modules Analyzed: $($results.ModuleResults.Count)" -ForegroundColor White
Write-Host "Total Functions: $(($results.ModuleResults | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum)" -ForegroundColor White
Write-Host "PSScriptAnalyzer Issues: $($results.TestResults.Count)" -ForegroundColor White

# Windows-specific next steps
Write-Host "`n📋 Windows-Specific Next Steps:" -ForegroundColor Cyan
if ($results.OverallScore -lt 80) {
    Write-Host "1. Address critical issues first" -ForegroundColor Yellow
    Write-Host "2. Replace hardcoded Windows paths with relative paths" -ForegroundColor Yellow
    Write-Host "3. Add proper error handling for Windows-specific operations" -ForegroundColor Yellow
    Write-Host "4. Test on different Windows versions" -ForegroundColor Yellow
}
else {
    Write-Host "1. Maintain current quality standards" -ForegroundColor Green
    Write-Host "2. Consider Windows-specific optimizations" -ForegroundColor White
    Write-Host "3. Test compatibility with different PowerShell versions" -ForegroundColor White
}

Write-Host "`n✅ Windows validation complete!" -ForegroundColor Green

# Provide command examples
Write-Host "`n💡 Useful Windows Commands:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "• Run PSScriptAnalyzer: Invoke-ScriptAnalyzer -Path . -Recurse" -ForegroundColor White
Write-Host "• Run Pester tests: Invoke-Pester -Path .\Tests" -ForegroundColor White
Write-Host "• Check execution policy: Get-ExecutionPolicy" -ForegroundColor White
Write-Host "• Set execution policy: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
Write-Host "• Import module: Import-Module .\modules\ScratchCore\ScratchCore.psm1 -Force" -ForegroundColor White 