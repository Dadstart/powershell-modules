function Validate-CodeQuality {
    <#
    .SYNOPSIS
        Validates PowerShell code quality against best practices and community standards.

    .DESCRIPTION
        This function performs comprehensive validation of PowerShell code including:
        - PSScriptAnalyzer compliance
        - Function naming conventions
        - Parameter validation
        - Documentation completeness
        - Error handling patterns
        - Module structure validation
        - Test coverage assessment

    .PARAMETER Path
        Path to the directory or file to validate. Defaults to the current directory.

    .PARAMETER ModuleName
        Specific module name to validate. If not specified, validates all modules.

    .PARAMETER IncludeTests
        Include test files in validation.

    .PARAMETER Detailed
        Provide detailed output with specific issues and recommendations.

    .PARAMETER FixIssues
        Automatically fix common issues where possible.

    .EXAMPLE
        Validate-CodeQuality -Path ".\modules" -Detailed

        Validates all modules in the modules directory with detailed output.

    .EXAMPLE
        Validate-CodeQuality -ModuleName "ScratchCore" -FixIssues

        Validates the ScratchCore module and attempts to fix common issues.

    .OUTPUTS
        PSCustomObject with validation results and recommendations.

    .NOTES
        This function requires PSScriptAnalyzer to be installed.
        Run: Install-Module -Name PSScriptAnalyzer -Force
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.',

        [Parameter()]
        [string]$ModuleName,

        [Parameter()]
        [switch]$IncludeTests,

        [Parameter()]
        [switch]$Detailed,

        [Parameter()]
        [switch]$FixIssues
    )

    begin {
        Write-Message "🔍 Starting PowerShell code quality validation..." -Type Processing
        
        # Check if PSScriptAnalyzer is available
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Write-Message "⚠️ PSScriptAnalyzer not found. Installing..." -Type Warning
            try {
                Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
                Import-Module PSScriptAnalyzer
            }
            catch {
                Write-Message "❌ Failed to install PSScriptAnalyzer: $($_.Exception.Message)" -Type Error
                return
            }
        }

        $validationResults = @{
            OverallScore = 0
            Issues = @()
            Recommendations = @()
            ModuleResults = @()
            TestResults = @()
        }

        $totalIssues = 0
        $criticalIssues = 0
    }

    process {
        try {
            # Determine what to validate
            if ($ModuleName) {
                $modulesToValidate = @(Get-ChildItem -Path $Path -Directory -Filter $ModuleName -ErrorAction SilentlyContinue)
            }
            else {
                $modulesToValidate = @(Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue)
            }

            if ($modulesToValidate.Count -eq 0) {
                Write-Message "❌ No modules found to validate in: $Path" -Type Error
                return
            }

            Write-Message "📦 Found $($modulesToValidate.Count) module(s) to validate" -Type Info

            foreach ($moduleDir in $modulesToValidate) {
                Write-Message "`n🔍 Validating module: $($moduleDir.Name)" -Type Processing
                
                $moduleResult = Test-ModuleQuality -ModulePath $moduleDir.FullName -Detailed:$Detailed
                $validationResults.ModuleResults += $moduleResult
                
                $totalIssues += $moduleResult.IssueCount
                $criticalIssues += $moduleResult.CriticalIssues
            }

            # Run PSScriptAnalyzer
            Write-Message "`n🔍 Running PSScriptAnalyzer..." -Type Processing
            $scriptAnalyzerSettings = Join-Path $Path "config\PSScriptAnalyzerSettings.psd1"
            
            if (Test-Path $scriptAnalyzerSettings) {
                $analyzerResults = Invoke-ScriptAnalyzer -Path $Path -Settings $scriptAnalyzerSettings -Recurse
            }
            else {
                $analyzerResults = Invoke-ScriptAnalyzer -Path $Path -Recurse
            }

            $validationResults.TestResults = $analyzerResults

            # Calculate overall score
            $maxScore = 100
            $deductions = ($totalIssues * 2) + ($criticalIssues * 5)
            $validationResults.OverallScore = [Math]::Max(0, $maxScore - $deductions)

            # Generate recommendations
            $validationResults.Recommendations = Get-Recommendations -Results $validationResults

        }
        catch {
            Write-Message "❌ Validation failed: $($_.Exception.Message)" -Type Error
            throw
        }
    }

    end {
        # Display results
        Show-ValidationResults -Results $validationResults -Detailed:$Detailed

        # Return results object
        return [PSCustomObject]$validationResults
    }
}

function Test-ModuleQuality {
    <#
    .SYNOPSIS
        Tests the quality of a specific PowerShell module.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter()]
        [switch]$Detailed
    )

    $moduleName = Split-Path $ModulePath -Leaf
    $result = @{
        ModuleName = $moduleName
        Score = 0
        Issues = @()
        CriticalIssues = 0
        IssueCount = 0
        Functions = @()
        Tests = @()
    }

    Write-Message "  📁 Module path: $ModulePath" -Type Verbose

    # Check module manifest
    $manifestPath = Join-Path $ModulePath "$moduleName.psd1"
    if (Test-Path $manifestPath) {
        try {
            $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
            Write-Message "  ✅ Module manifest is valid" -Type Success
        }
        catch {
            $result.Issues += "Module manifest is invalid: $($_.Exception.Message)"
            $result.CriticalIssues++
            Write-Message "  ❌ Module manifest is invalid: $($_.Exception.Message)" -Type Error
        }
    }
    else {
        $result.Issues += "Module manifest not found"
        $result.CriticalIssues++
        Write-Message "  ❌ Module manifest not found" -Type Error
    }

    # Check module structure
    $publicDir = Join-Path $ModulePath "Public"
    $privateDir = Join-Path $ModulePath "Private"
    $testsDir = Join-Path $ModulePath "Tests"

    if (-not (Test-Path $publicDir)) {
        $result.Issues += "Public directory not found"
        Write-Message "  ⚠️ Public directory not found" -Type Warning
    }

    if (-not (Test-Path $privateDir)) {
        $result.Issues += "Private directory not found"
        Write-Message "  ⚠️ Private directory not found" -Type Warning
    }

    # Validate public functions
    if (Test-Path $publicDir) {
        $publicFunctions = Get-ChildItem -Path $publicDir -Filter "*.ps1" -File
        Write-Message "  📋 Found $($publicFunctions.Count) public functions" -Type Info

        foreach ($functionFile in $publicFunctions) {
            $functionResult = Test-FunctionQuality -FunctionPath $functionFile.FullName -Detailed:$Detailed
            $result.Functions += $functionResult
            
            if ($functionResult.Issues.Count -gt 0) {
                $result.Issues += "Function $($functionResult.FunctionName): $($functionResult.Issues -join '; ')"
                $result.IssueCount += $functionResult.Issues.Count
            }
        }
    }

    # Check for tests
    if (Test-Path $testsDir) {
        $testFiles = Get-ChildItem -Path $testsDir -Filter "*.ps1" -File
        Write-Message "  🧪 Found $($testFiles.Count) test files" -Type Info
        
        foreach ($testFile in $testFiles) {
            $testResult = Test-TestQuality -TestPath $testFile.FullName
            $result.Tests += $testResult
        }
    }
    else {
        $result.Issues += "No Tests directory found"
        Write-Message "  ⚠️ No Tests directory found" -Type Warning
    }

    # Calculate module score
    $maxScore = 100
    $deductions = ($result.IssueCount * 2) + ($result.CriticalIssues * 5)
    $result.Score = [Math]::Max(0, $maxScore - $deductions)

    return [PSCustomObject]$result
}

function Test-FunctionQuality {
    <#
    .SYNOPSIS
        Tests the quality of a PowerShell function.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionPath,

        [Parameter()]
        [switch]$Detailed
    )

    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($FunctionPath)
    $result = @{
        FunctionName = $functionName
        Issues = @()
        Score = 0
    }

    try {
        $functionContent = Get-Content -Path $FunctionPath -Raw -ErrorAction Stop
        
        # Check for function declaration
        if ($functionContent -notmatch "function\s+$functionName\s*{") {
            $result.Issues += "Function declaration not found"
        }

        # Check for CmdletBinding
        if ($functionContent -notmatch '\[CmdletBinding\(\)\]') {
            $result.Issues += "Missing [CmdletBinding()] attribute"
        }

        # Check for comment-based help
        if ($functionContent -notmatch '\.SYNOPSIS') {
            $result.Issues += "Missing comment-based help"
        }

        # Check for parameter validation
        if ($functionContent -match '\[Parameter\(\)\]' -and $functionContent -notmatch '\[Validate') {
            $result.Issues += "Parameters missing validation attributes"
        }

        # Check for error handling
        if ($functionContent -notmatch 'try\s*{' -and $functionContent -notmatch '-ErrorAction') {
            $result.Issues += "No error handling detected"
        }

        # Check for Write-Message usage (project-specific)
        if ($functionContent -match 'Write-Host|Write-Warning|Write-Error' -and $functionContent -notmatch 'Write-Message') {
            $result.Issues += "Should use Write-Message instead of direct Write-* cmdlets"
        }

        # Check line length
        $longLines = @($functionContent -split "`n" | Where-Object { $_.Length -gt 120 })
        if ($longLines.Count -gt 0) {
            $result.Issues += "$($longLines.Count) lines exceed 120 characters"
        }

        # Calculate function score
        $maxScore = 100
        $deductions = $result.Issues.Count * 10
        $result.Score = [Math]::Max(0, $maxScore - $deductions)

    }
    catch {
        $result.Issues += "Failed to read function file: $($_.Exception.Message)"
        $result.Score = 0
    }

    return [PSCustomObject]$result
}

function Test-TestQuality {
    <#
    .SYNOPSIS
        Tests the quality of test files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestPath
    )

    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestPath)
    $result = @{
        TestName = $testName
        Issues = @()
        Score = 0
    }

    try {
        $testContent = Get-Content -Path $TestPath -Raw -ErrorAction Stop
        
        # Check for Pester structure
        if ($testContent -notmatch 'Describe\s+') {
            $result.Issues += "Missing Pester Describe block"
        }

        if ($testContent -notmatch 'It\s+') {
            $result.Issues += "Missing Pester It blocks"
        }

        # Check for test coverage
        if ($testContent -notmatch 'Should\s+-') {
            $result.Issues += "Missing Pester assertions"
        }

        # Calculate test score
        $maxScore = 100
        $deductions = $result.Issues.Count * 25
        $result.Score = [Math]::Max(0, $maxScore - $deductions)

    }
    catch {
        $result.Issues += "Failed to read test file: $($_.Exception.Message)"
        $result.Score = 0
    }

    return [PSCustomObject]$result
}

function Get-Recommendations {
    <#
    .SYNOPSIS
        Generates recommendations based on validation results.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Results
    )

    $recommendations = @()

    # Overall recommendations
    if ($Results.OverallScore -lt 80) {
        $recommendations += "Overall code quality needs improvement. Focus on critical issues first."
    }

    if ($Results.CriticalIssues -gt 0) {
        $recommendations += "Address critical issues immediately as they may cause runtime failures."
    }

    # Module-specific recommendations
    foreach ($moduleResult in $Results.ModuleResults) {
        if ($moduleResult.CriticalIssues -gt 0) {
            $recommendations += "Module '$($moduleResult.ModuleName)' has critical issues that need immediate attention."
        }

        if ($moduleResult.Tests.Count -eq 0) {
            $recommendations += "Module '$($moduleResult.ModuleName)' lacks test coverage. Add unit tests."
        }

        foreach ($function in $moduleResult.Functions) {
            if ($function.Issues.Count -gt 3) {
                $recommendations += "Function '$($function.FunctionName)' has multiple issues. Review and refactor."
            }
        }
    }

    # PSScriptAnalyzer recommendations
    $analyzerIssues = $Results.TestResults | Group-Object RuleName | Sort-Object Count -Descending
    foreach ($issue in $analyzerIssues) {
        if ($issue.Count -gt 5) {
            $recommendations += "Address '$($issue.Name)' violations ($($issue.Count) instances)."
        }
    }

    return $recommendations
}

function Show-ValidationResults {
    <#
    .SYNOPSIS
        Displays validation results in a formatted manner.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Results,

        [Parameter()]
        [switch]$Detailed
    )

    Write-Message "`n📊 Validation Results Summary" -Type Info
    Write-Message "================================" -Type Info
    Write-Message "Overall Score: $($Results.OverallScore)/100" -Type $(if ($Results.OverallScore -ge 80) { 'Success' } elseif ($Results.OverallScore -ge 60) { 'Warning' } else { 'Error' })
    Write-Message "Total Issues: $($Results.Issues.Count)" -Type $(if ($Results.Issues.Count -eq 0) { 'Success' } else { 'Warning' })
    Write-Message "Critical Issues: $criticalIssues" -Type $(if ($criticalIssues -eq 0) { 'Success' } else { 'Error' })

    # Module results
    Write-Message "`n📦 Module Results:" -Type Info
    foreach ($moduleResult in $Results.ModuleResults) {
        $status = if ($moduleResult.Score -ge 80) { '🟢' } elseif ($moduleResult.Score -ge 60) { '🟡' } else { '🔴' }
        Write-Message "$status $($moduleResult.ModuleName): $($moduleResult.Score)/100 ($($moduleResult.IssueCount) issues)" -Type Info
        
        if ($Detailed -and $moduleResult.Issues.Count -gt 0) {
            foreach ($issue in $moduleResult.Issues) {
                Write-Message "  ⚠️ $issue" -Type Warning
            }
        }
    }

    # PSScriptAnalyzer results
    if ($Results.TestResults.Count -gt 0) {
        Write-Message "`n🔍 PSScriptAnalyzer Results:" -Type Info
        $ruleGroups = $Results.TestResults | Group-Object RuleName | Sort-Object Count -Descending
        
        foreach ($rule in $ruleGroups) {
            $severity = ($Results.TestResults | Where-Object { $_.RuleName -eq $rule.Name } | Select-Object -First 1).Severity
            $color = switch ($severity) {
                'Error' { 'Error' }
                'Warning' { 'Warning' }
                default { 'Info' }
            }
            
            Write-Message "  $($rule.Name): $($rule.Count) violations" -Type $color
        }
    }

    # Recommendations
    if ($Results.Recommendations.Count -gt 0) {
        Write-Message "`n💡 Recommendations:" -Type Info
        foreach ($recommendation in $Results.Recommendations) {
            Write-Message "  • $recommendation" -Type Info
        }
    }

    # Final assessment
    Write-Message "`n🎯 Final Assessment:" -Type Info
    if ($Results.OverallScore -ge 90) {
        Write-Message "Excellent code quality! Keep up the good work." -Type Success
    }
    elseif ($Results.OverallScore -ge 80) {
        Write-Message "Good code quality with room for improvement." -Type Success
    }
    elseif ($Results.OverallScore -ge 60) {
        Write-Message "Code quality needs attention. Review recommendations." -Type Warning
    }
    else {
        Write-Message "Code quality requires significant improvement. Prioritize critical issues." -Type Error
    }
}

# Export the main function
Export-ModuleMember -Function Validate-CodeQuality 