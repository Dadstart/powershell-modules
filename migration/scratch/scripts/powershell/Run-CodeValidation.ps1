<#
.SYNOPSIS
    Demonstrates PowerShell code validation using the Validate-CodeQuality function.

.DESCRIPTION
    This script shows how to use the Validate-CodeQuality function to check
    PowerShell code against best practices and community standards.

.EXAMPLE
    .\Run-CodeValidation.ps1

    Runs validation on all modules in the current directory.

.EXAMPLE
    .\Run-CodeValidation.ps1 -ModuleName "ScratchCore" -Detailed

    Runs detailed validation on the ScratchCore module only.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ModuleName,

    [Parameter()]
    [switch]$Detailed,

    [Parameter()]
    [switch]$FixIssues
)

# Import required modules
$modulesPath = Join-Path $PSScriptRoot "..\..\modules"
$scriptsPath = Join-Path $PSScriptRoot "..\..\scripts\powershell"

# Import ScratchCore module for Write-Message function
if (-not (Get-Module -Name ScratchCore)) {
    Import-Module (Join-Path $modulesPath "ScratchCore\ScratchCore.psm1") -Force
}

# Import the validation function
. (Join-Path $scriptsPath "Validate-CodeQuality.ps1")

Write-Message "🚀 PowerShell Code Quality Validation Demo" -Type Info
Write-Message "=============================================" -Type Info

# Set the working directory to the project root
$projectRoot = Split-Path $PSScriptRoot -Parent | Split-Path -Parent
Set-Location $projectRoot

Write-Message "📁 Working directory: $projectRoot" -Type Info

# Run validation based on parameters
if ($ModuleName) {
    Write-Message "`n🔍 Running validation for module: $ModuleName" -Type Processing
    
    $results = Validate-CodeQuality -Path $modulesPath -ModuleName $ModuleName -Detailed:$Detailed -FixIssues:$FixIssues
}
else {
    Write-Message "`n🔍 Running validation for all modules" -Type Processing
    
    $results = Validate-CodeQuality -Path $modulesPath -Detailed:$Detailed -FixIssues:$FixIssues
}

# Additional analysis and recommendations
Write-Message "`n📈 Additional Analysis" -Type Info
Write-Message "=====================" -Type Info

# Check for common issues across modules
$commonIssues = @()
foreach ($moduleResult in $results.ModuleResults) {
    foreach ($function in $moduleResult.Functions) {
        if ($function.Issues -contains "Missing comment-based help") {
            $commonIssues += "Missing documentation in $($moduleResult.ModuleName)\$($function.FunctionName)"
        }
        if ($function.Issues -contains "Should use Write-Message instead of direct Write-* cmdlets") {
            $commonIssues += "Direct Write-* usage in $($moduleResult.ModuleName)\$($function.FunctionName)"
        }
    }
}

if ($commonIssues.Count -gt 0) {
    Write-Message "`n🔍 Common Issues Found:" -Type Warning
    foreach ($issue in $commonIssues | Select-Object -First 5) {
        Write-Message "  • $issue" -Type Warning
    }
    
    if ($commonIssues.Count -gt 5) {
        Write-Message "  ... and $($commonIssues.Count - 5) more issues" -Type Warning
    }
}

# Performance recommendations
Write-Message "`n⚡ Performance Recommendations:" -Type Info
if ($results.ModuleResults.Count -gt 3) {
    Write-Message "  • Consider consolidating similar modules to reduce loading time" -Type Info
}

$functionsWithIssues = ($results.ModuleResults | ForEach-Object { $_.Functions } | Where-Object { $_.Issues.Count -gt 0 }).Count
if ($functionsWithIssues -gt 10) {
    Write-Message "  • Multiple functions have quality issues - consider a refactoring sprint" -Type Warning
}

# Security recommendations
Write-Message "`n🔒 Security Recommendations:" -Type Info
$hasValidationIssues = $results.ModuleResults | ForEach-Object { 
    $_.Functions | Where-Object { $_.Issues -contains "Parameters missing validation attributes" }
} | Measure-Object | Select-Object -ExpandProperty Count

if ($hasValidationIssues -gt 0) {
    Write-Message "  • Add parameter validation to prevent injection attacks" -Type Warning
}

# Testing recommendations
$modulesWithoutTests = ($results.ModuleResults | Where-Object { $_.Tests.Count -eq 0 }).Count
if ($modulesWithoutTests -gt 0) {
    Write-Message "  • $modulesWithoutTests module(s) lack test coverage - add unit tests" -Type Warning
}

# Export results to file
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = Join-Path $projectRoot "validation-results-$timestamp.json"

try {
    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Message "`n💾 Results exported to: $resultsFile" -Type Success
}
catch {
    Write-Message "`n⚠️ Failed to export results: $($_.Exception.Message)" -Type Warning
}

# Summary
Write-Message "`n🎯 Validation Summary" -Type Info
Write-Message "===================" -Type Info
Write-Message "Overall Score: $($results.OverallScore)/100" -Type $(if ($results.OverallScore -ge 80) { 'Success' } elseif ($results.OverallScore -ge 60) { 'Warning' } else { 'Error' })
Write-Message "Modules Analyzed: $($results.ModuleResults.Count)" -Type Info
Write-Message "Total Functions: $(($results.ModuleResults | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum)" -Type Info
Write-Message "PSScriptAnalyzer Issues: $($results.TestResults.Count)" -Type Info

# Next steps
Write-Message "`n📋 Next Steps:" -Type Info
if ($results.OverallScore -lt 80) {
    Write-Message "  1. Address critical issues first" -Type Warning
    Write-Message "  2. Add missing documentation" -Type Warning
    Write-Message "  3. Implement proper error handling" -Type Warning
    Write-Message "  4. Add unit tests for untested modules" -Type Warning
}
else {
    Write-Message "  1. Maintain current quality standards" -Type Success
    Write-Message "  2. Add more comprehensive tests" -Type Info
    Write-Message "  3. Consider performance optimizations" -Type Info
}

Write-Message "`n✅ Validation complete!" -Type Success 