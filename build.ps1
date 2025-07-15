#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for PowerShell modules with PowerShell 7.4+ requirements.

.DESCRIPTION
    This script provides build tasks for PowerShell modules, ensuring compatibility
    with PowerShell 7.4+ (LTS version) and enforcing version requirements.

.PARAMETER Task
    The build task to execute. Default is 'Build'.

.PARAMETER Configuration
    Build configuration. Default is 'Release'.

.EXAMPLE
    .\build.ps1
    .\build.ps1 -Task Test
    .\build.ps1 -Task Clean -Configuration Debug
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Clean', 'Build', 'Test', 'Analyze', 'Package', 'Publish', 'All')]
    [string]$Task = 'Build',
    
    [Parameter()]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release'
)

#Requires -Version 7.4

# Script variables
$Script:ErrorActionPreference = 'Stop'
$Script:BuildRoot = $PSScriptRoot
$Script:BuildOutput = Join-Path $BuildRoot 'BuildOutput'
$Script:ReleaseOutput = Join-Path $BuildRoot 'Release'

# Ensure minimum PowerShell version
$MinimumVersion = [Version]'7.4.0'
$CurrentVersion = $PSVersionTable.PSVersion

if ($CurrentVersion -lt $MinimumVersion) {
    throw "PowerShell $MinimumVersion or higher is required. Current version: $CurrentVersion"
}

Write-Host "PowerShell version check passed: $CurrentVersion" -ForegroundColor Green

function Invoke-Clean {
    <#
    .SYNOPSIS
        Cleans build output directories.
    #>
    Write-Host "Cleaning build output..." -ForegroundColor Yellow
    
    $PathsToClean = @(
        $Script:BuildOutput,
        $Script:ReleaseOutput
    )
    
    foreach ($Path in $PathsToClean) {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force
            Write-Host "Cleaned: $Path" -ForegroundColor Green
        }
    }
}

function Invoke-Build {
    <#
    .SYNOPSIS
        Builds PowerShell modules.
    #>
    Write-Host "Building PowerShell modules..." -ForegroundColor Yellow
    
    # Create build output directory
    if (-not (Test-Path $Script:BuildOutput)) {
        New-Item -Path $Script:BuildOutput -ItemType Directory -Force | Out-Null
    }
    
    # Find all module manifest files
    $ModuleManifests = Get-ChildItem -Path $BuildRoot -Filter '*.psd1' -Recurse | 
        Where-Object { $_.Name -ne '*.psd1' -and $_.Directory.Name -ne 'Tests' }
    
    foreach ($Manifest in $ModuleManifests) {
        $ModuleName = $Manifest.BaseName
        $ModulePath = $Manifest.Directory.FullName
        
        Write-Host "Building module: $ModuleName" -ForegroundColor Cyan
        
        # Validate module manifest
        try {
            $ManifestData = Import-PowerShellDataFile -Path $Manifest.FullName
            Write-Host "  ✓ Manifest validation passed" -ForegroundColor Green
        }
        catch {
            Write-Error "  ✗ Manifest validation failed for $ModuleName : $_"
            continue
        }
        
        # Copy module to build output
        $BuildModulePath = Join-Path $Script:BuildOutput $ModuleName
        if (Test-Path $BuildModulePath) {
            Remove-Item -Path $BuildModulePath -Recurse -Force
        }
        
        Copy-Item -Path $ModulePath -Destination $BuildModulePath -Recurse -Force
        Write-Host "  ✓ Module copied to build output" -ForegroundColor Green
    }
    
    Write-Host "Build completed successfully!" -ForegroundColor Green
}

function Invoke-Analyze {
    <#
    .SYNOPSIS
        Runs PSScriptAnalyzer on PowerShell modules.
    #>
    Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Yellow
    
    # Check if PSScriptAnalyzer is available
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Warning "PSScriptAnalyzer module not found. Installing PSScriptAnalyzer..."
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
    }
    
    # Import PSScriptAnalyzer
    Import-Module PSScriptAnalyzer -Force
    
    # Define paths to analyze
    $PathsToAnalyze = @(
        Join-Path $BuildRoot 'Modules'
        Join-Path $BuildRoot 'Tests'
    )
    
    # Check if custom settings file exists
    $SettingsPath = Join-Path $BuildRoot 'PSScriptAnalyzerSettings.psd1'
    $SettingsParam = if (Test-Path $SettingsPath) { @{ Settings = $SettingsPath } } else { @{} }
    
    $AnalysisResults = @()
    
    foreach ($Path in $PathsToAnalyze) {
        if (Test-Path $Path) {
            Write-Host "Analyzing: $Path" -ForegroundColor Cyan
            
            $Results = Invoke-ScriptAnalyzer -Path $Path -Recurse @SettingsParam
            
            if ($Results) {
                $AnalysisResults += $Results
                
                # Group results by severity
                $Errors = $Results | Where-Object { $_.Severity -eq 'Error' }
                $Warnings = $Results | Where-Object { $_.Severity -eq 'Warning' }
                $Information = $Results | Where-Object { $_.Severity -eq 'Information' }
                
                Write-Host "  Found $($Errors.Count) errors, $($Warnings.Count) warnings, $($Information.Count) information items" -ForegroundColor Yellow
                
                # Display errors and warnings
                if ($Errors) {
                    Write-Host "  Errors:" -ForegroundColor Red
                    foreach ($AnalysisError in $Errors) {
                        Write-Host "    $($AnalysisError.RuleName): $($AnalysisError.Message) at $($AnalysisError.ScriptName):$($AnalysisError.Line)" -ForegroundColor Red
                    }
                }
                
                if ($Warnings) {
                    Write-Host "  Warnings:" -ForegroundColor Yellow
                    foreach ($Warning in $Warnings) {
                        Write-Host "    $($Warning.RuleName): $($Warning.Message) at $($Warning.ScriptName):$($Warning.Line)" -ForegroundColor Yellow
                    }
                }
            }
            else {
                Write-Host "  ✓ No issues found" -ForegroundColor Green
            }
        }
    }
    
    # Save analysis results
    if ($AnalysisResults) {
        $AnalysisOutputPath = Join-Path $Script:BuildOutput 'PSScriptAnalyzerResults.xml'
        $AnalysisResults | Export-Clixml -Path $AnalysisOutputPath
        Write-Host "Analysis results saved to: $AnalysisOutputPath" -ForegroundColor Cyan
    }
    
    # Fail build if there are errors
    $ErrorCount = ($AnalysisResults | Where-Object { $_.Severity -eq 'Error' }).Count
    if ($ErrorCount -gt 0) {
        Write-Error "PSScriptAnalyzer found $ErrorCount errors. Build failed."
        exit 1
    }
    
    Write-Host "PSScriptAnalyzer completed successfully!" -ForegroundColor Green
}

function Invoke-Test {
    <#
    .SYNOPSIS
        Runs Pester tests for PowerShell modules.
    #>
    Write-Host "Running tests..." -ForegroundColor Yellow
    
    # Check if Pester is available
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning "Pester module not found. Installing Pester..."
        Install-Module -Name Pester -Force -Scope CurrentUser
    }
    
    # Find test files
    $TestFiles = Get-ChildItem -Path $BuildRoot -Filter '*.Tests.ps1' -Recurse
    
    if (-not $TestFiles) {
        Write-Warning "No test files found. Skipping tests."
        return
    }
    
    $TestResults = Invoke-Pester -Path $TestFiles.FullName -OutputFormat NUnitXml -OutputFile (Join-Path $Script:BuildOutput 'TestResults.xml') -PassThru
    
    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Tests failed: $($TestResults.FailedCount) failed, $($TestResults.PassedCount) passed"
        exit 1
    }
    
    Write-Host "All tests passed: $($TestResults.PassedCount) tests" -ForegroundColor Green
}

function Invoke-Package {
    <#
    .SYNOPSIS
        Creates package files for PowerShell modules.
    #>
    Write-Host "Creating packages..." -ForegroundColor Yellow
    
    if (-not (Test-Path $Script:BuildOutput)) {
        Write-Error "Build output not found. Run Build task first."
        return
    }
    
    # Create release output directory
    if (-not (Test-Path $Script:ReleaseOutput)) {
        New-Item -Path $Script:ReleaseOutput -ItemType Directory -Force | Out-Null
    }
    
    $Modules = Get-ChildItem -Path $Script:BuildOutput -Directory
    
    foreach ($Module in $Modules) {
        $ModuleName = $Module.Name
        $PackagePath = Join-Path $Script:ReleaseOutput "$ModuleName.zip"
        
        Write-Host "Creating package: $ModuleName" -ForegroundColor Cyan
        
        # Create ZIP package
        Compress-Archive -Path $Module.FullName -DestinationPath $PackagePath -Force
        Write-Host "  ✓ Package created: $PackagePath" -ForegroundColor Green
    }
    
    Write-Host "Packaging completed!" -ForegroundColor Green
}

function Invoke-Publish {
    <#
    .SYNOPSIS
        Publishes modules to PowerShell Gallery (placeholder).
    #>
    Write-Host "Publish task is not implemented yet." -ForegroundColor Yellow
    Write-Host "To publish to PowerShell Gallery, use:" -ForegroundColor Cyan
    Write-Host "  Publish-Module -Path <module-path> -NuGetApiKey <api-key>" -ForegroundColor White
}

# Main execution
Write-Host "PowerShell Modules Build Script" -ForegroundColor Magenta
Write-Host "PowerShell Version: $CurrentVersion" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Cyan
Write-Host "Task: $Task" -ForegroundColor Cyan
Write-Host ""

switch ($Task) {
    'Clean' { Invoke-Clean }
    'Build' { Invoke-Build }
    'Analyze' { Invoke-Analyze }
    'Test' { Invoke-Test }
    'Package' { Invoke-Package }
    'Publish' { Invoke-Publish }
    'All' { 
        Invoke-Clean
        Invoke-Build
        Invoke-Analyze
        Invoke-Test
        Invoke-Package
    }
    default {
        Write-Error "Unknown task: $Task"
        exit 1
    }
}

Write-Host ""
Write-Host "Build script completed successfully!" -ForegroundColor Green 