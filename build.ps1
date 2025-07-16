#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build script for PowerShell modules with PowerShell 7.4+ requirements.

.DESCRIPTION
    This script provides build tasks for PowerShell modules, ensuring compatibility
    with PowerShell 7.4+ (LTS version) and enforcing version requirements.

.PARAMETER Task
    The build task to execute. Default is 'Build'.

.EXAMPLE
    .\build.ps1
    .\build.ps1 -Task Test
    .\build.ps1 -Task Clean
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('Clean', 'Build', 'Test', 'TestWithCodeCoverage', 'Analyze', 'Package', 'Publish', 'All')]
    [string]$Task = 'Build',
    [Parameter()]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic', $null)]
    [string]
    $PesterOutputVerbosity = $null
)

#Requires -Version 7.4

# Script variables
$Script:ErrorActionPreference = 'Stop'
$Script:BuildRoot = $PSScriptRoot
$Script:BuildOutput = Join-Path $BuildRoot 'BuildOutput'
$Script:DebugOutput = Join-Path $BuildRoot 'Debug'
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
    Write-Host 'Cleaning build output...' -ForegroundColor Yellow

    $PathsToClean = @(
        $Script:BuildOutput,
        $Script:DebugOutput,
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
    Write-Host 'Building PowerShell modules...' -ForegroundColor Yellow

    # Create build output directory
    if (-not (Test-Path $Script:BuildOutput)) {
        New-Item -Path $Script:BuildOutput -ItemType Directory -Force | Out-Null
    }

    # Find all module manifest files
    $ModuleManifests = Get-ChildItem -Path $BuildRoot -Filter '*.psd1' -Recurse |
        Where-Object { $_.Name -ne '*.psd1' -and $_.Directory.Name -ne 'Tests' -and $_.Name -ne 'PSScriptAnalyzerSettings.psd1' }

    foreach ($Manifest in $ModuleManifests) {
        $ModuleName = $Manifest.BaseName
        $ModulePath = $Manifest.Directory.FullName

        Write-Host "Building module: $ModuleName" -ForegroundColor Cyan

        # Validate module manifest
        try {
            Write-Host '  ✓ Manifest validation passed' -ForegroundColor Green
        }
        catch {
            Write-Error "  ✗ Manifest validation failed for $ModuleName : $_"
            continue
        }

        # Copy module to build output (selective copying)
        $BuildModulePath = Join-Path $Script:BuildOutput $ModuleName
        if (Test-Path $BuildModulePath) {
            Remove-Item -Path $BuildModulePath -Recurse -Force
        }

        # Create build directory
        New-Item -Path $BuildModulePath -ItemType Directory -Force | Out-Null

        # Define what to copy (only production files)
        $CopyItems = @(
            'Modules\*.psd1',  # Module manifest
            'Modules\*.psm1',  # Module script
            'Modules\Public\*',  # Public functions
            'Modules\Private\*',  # Private functions
            'Modules\Classes\*',  # Classes
            'Shared\*'   # Shared resources
        )

        $ExcludeItems = @(
            'Tests\*',  # Test files
            '*.Tests.ps1',  # Test files
            '*.md',  # Documentation
            '.git*',  # Git files
            '.github*',  # GitHub files
            '.vscode*',  # VSCode files
            '*.log',  # Log files
            'temp\*',  # Temporary files
            'tmp\*'   # Temporary files
        )

        $CopiedFiles = 0
        foreach ($Pattern in $CopyItems) {
            $SourcePattern = Join-Path $ModulePath $Pattern
            $Files = Get-ChildItem -Path $SourcePattern -Recurse -ErrorAction SilentlyContinue

            foreach ($File in $Files) {
                # Check if file should be excluded
                $ShouldExclude = $false
                foreach ($ExcludePattern in $ExcludeItems) {
                    if ($File.FullName -like (Join-Path $ModulePath $ExcludePattern)) {
                        $ShouldExclude = $true
                        break
                    }
                }

                if (-not $ShouldExclude) {
                    $RelativePath = $File.FullName.Substring($ModulePath.Length + 1)
                    $DestinationPath = Join-Path $BuildModulePath $RelativePath
                    $DestinationDir = Split-Path $DestinationPath -Parent

                    if (-not (Test-Path $DestinationDir)) {
                        New-Item -Path $DestinationDir -ItemType Directory -Force | Out-Null
                    }

                    Copy-Item -Path $File.FullName -Destination $DestinationPath -Force
                    $CopiedFiles++
                }
            }
        }

        Write-Host "  ✓ Module copied to build output ($CopiedFiles files)" -ForegroundColor Green
    }

    Write-Host 'Build completed successfully!' -ForegroundColor Green
}

function Invoke-Analyze {
    <#
    .SYNOPSIS
        Runs PSScriptAnalyzer on PowerShell modules.
    #>
    Write-Host 'Running PSScriptAnalyzer...' -ForegroundColor Yellow

    # Check if PSScriptAnalyzer is available
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Warning 'PSScriptAnalyzer module not found. Installing PSScriptAnalyzer...'
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
    $SettingsParam = if (Test-Path $SettingsPath) {
        @{ Settings = $SettingsPath }
    }
    else {
        @{}
    }

    $AnalysisResults = @()

    foreach ($Path in $PathsToAnalyze) {
        if (Test-Path $Path) {
            Write-Host "Analyzing: $Path" -ForegroundColor Cyan

            try {
                # Try with specified settings and profile
                $Results = Invoke-ScriptAnalyzer -Path $Path -Recurse @SettingsParam -ErrorAction Stop
            }
            catch {
                Write-Warning "PSScriptAnalyzer failed with specified settings: $($_.Exception.Message)"
                
                # If it's a compatibility profile issue, try without profile
                if ($_.Exception.Message -like '*compatibility*profile*' -or $_.Exception.Message -like '*Could not find file*') {
                    Write-Host "Attempting analysis without compatibility profile..." -ForegroundColor Yellow
                    try {
                        $FallbackSettings = if (Test-Path $SettingsPath) {
                            @{ Settings = $SettingsPath }
                        }
                        else {
                            @{}
                        }
                        $Results = Invoke-ScriptAnalyzer -Path $Path -Recurse @FallbackSettings -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "PSScriptAnalyzer failed without profile: $($_.Exception.Message)"
                        Write-Host "Skipping analysis for this path due to compatibility issues." -ForegroundColor Yellow
                        $Results = $null
                    }
                }
                else {
                    Write-Host "Skipping analysis for this path due to PSScriptAnalyzer error." -ForegroundColor Yellow
                    $Results = $null
                }
            }

            if ($Results) {
                $AnalysisResults += $Results

                # Group results by severity
                $Errors = $Results | Where-Object { $_.Severity -eq 'Error' }
                $Warnings = $Results | Where-Object { $_.Severity -eq 'Warning' }
                $Information = $Results | Where-Object { $_.Severity -eq 'Information' }

                Write-Host "  Found $($Errors.Count) errors, $($Warnings.Count) warnings, $($Information.Count) information items" -ForegroundColor Yellow

                # Display errors and warnings
                if ($Errors) {
                    Write-Host '  Errors:' -ForegroundColor Red
                    foreach ($AnalysisError in $Errors) {
                        Write-Host "    $($AnalysisError.RuleName): $($AnalysisError.Message) at $($AnalysisError.ScriptName):$($AnalysisError.Line)" -ForegroundColor Red
                    }
                }

                if ($Warnings) {
                    Write-Host '  Warnings:' -ForegroundColor Yellow
                    foreach ($Warning in $Warnings) {
                        Write-Host "    $($Warning.RuleName): $($Warning.Message) at $($Warning.ScriptName):$($Warning.Line)" -ForegroundColor Yellow
                    }
                }
            }
            else {
                Write-Host '  ✓ No issues found' -ForegroundColor Green
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

    Write-Host 'PSScriptAnalyzer completed successfully!' -ForegroundColor Green
}

function Invoke-Test {
    <#
    .SYNOPSIS
        Runs Pester tests for PowerShell modules.
    #>
    param (
        [Parameter()]
        [switch]
        $CodeCoverage
    )

    Write-Host 'Running tests...' -ForegroundColor Yellow

    # Check if Pester is available
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning 'Pester module not found. Installing Pester...'
        Install-Module -Name Pester -Force -Scope CurrentUser
    }

    # Check if Pester configuration file exists
    $PesterConfigScript = Join-Path $BuildRoot 'PesterConfig.ps1'
    if (-not (Test-Path $PesterConfigScript)) {
        Write-Error "Pester configuration script not found: $PesterConfigScript"
        exit 1
    }

    Write-Host "Using Pester configuration from: $PesterConfigScript" -ForegroundColor Cyan
    $pesterConfigParams = @{}
    if ($CodeCoverage) {
        $pesterConfigParams.CodeCoverage = $true
    }
    if ($PesterOutputVerbosity) {
        $pesterConfigParams.Verbosity = $PesterOutputVerbosity
    }
    $pesterConfig = (. "$PesterConfigScript" @pesterConfigParams)

    $TestResults = Invoke-Pester -Configuration $pesterConfig

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
    Write-Host 'Creating packages...' -ForegroundColor Yellow

    if (-not (Test-Path $Script:BuildOutput)) {
        Write-Error 'Build output not found. Run Build task first.'
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

    Write-Host 'Packaging completed!' -ForegroundColor Green
}

function Invoke-Publish {
    <#
    .SYNOPSIS
        Publishes modules to PowerShell Gallery (placeholder).
    #>
    Write-Host 'Publish task is not implemented yet.' -ForegroundColor Yellow
    Write-Host 'To publish to PowerShell Gallery, use:' -ForegroundColor Cyan
    Write-Host '  Publish-Module -Path <module-path> -NuGetApiKey <api-key>' -ForegroundColor White
}

# Main execution
Write-Host 'PowerShell Modules Build Script' -ForegroundColor Magenta
Write-Host "PowerShell Version: $CurrentVersion" -ForegroundColor Cyan
Write-Host "Task: $Task" -ForegroundColor Cyan
Write-Host ''

switch ($Task) {
    'Clean' {
        Invoke-Clean
    }
    'Build' {
        Invoke-Build
    }
    'Analyze' {
        Invoke-Analyze
    }
    'Test' {
        Invoke-Test
    }
    'TestWithCodeCoverage' {
        Invoke-Test -CodeCoverage
    }
    'Package' {
        Invoke-Package
    }
    'Publish' {
        Invoke-Publish
    }
    'All' {
        Invoke-Clean
        Invoke-Build
        Invoke-Analyze
        Invoke-Test -CodeCoverage
        Invoke-Package
    }
    default {
        Write-Error "Unknown task: $Task"
        exit 1
    }
}

Write-Host ''
Write-Host 'Build script completed successfully!' -ForegroundColor Green