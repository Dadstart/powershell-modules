# Run PSScriptAnalyzer on the VideoFunctions project
Write-Host 'Running PSScriptAnalyzer on VideoFunctions project...' -ForegroundColor Green

# Analyze Public functions
Write-Host "`nAnalyzing Public functions..." -ForegroundColor Yellow
$publicResults = Invoke-ScriptAnalyzer -Path 'PowerShell/VideoFunctions/Public/' -Settings 'PSScriptAnalyzerSettings.psd1'

# Analyze Private functions
Write-Host "`nAnalyzing Private functions..." -ForegroundColor Yellow
$privateResults = Invoke-ScriptAnalyzer -Path 'PowerShell/VideoFunctions/Private/' -Settings 'PSScriptAnalyzerSettings.psd1'

# Combine results
$allResults = $publicResults + $privateResults

# Display summary
Write-Host "`n=== LINTING RESULTS SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total issues found: $($allResults.Count)" -ForegroundColor White

if ($allResults.Count -gt 0) {
    Write-Host "`nIssues by severity:" -ForegroundColor Yellow
    $allResults | Group-Object Severity | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
    
    Write-Host "`nIssues by rule:" -ForegroundColor Yellow
    $allResults | Group-Object RuleName | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
    
    # Show detailed results
    Write-Host "`n=== DETAILED RESULTS ===" -ForegroundColor Cyan
    $allResults | Format-Table -AutoSize
    
    # Save results to file
    $resultsFile = 'lint-results.csv'
    $allResults | Export-Csv -Path $resultsFile -NoTypeInformation
    Write-Host "`nDetailed results saved to: $resultsFile" -ForegroundColor Green
}
else {
    Write-Host "`n✅ No issues found! Your code follows PowerShell best practices." -ForegroundColor Green
} 