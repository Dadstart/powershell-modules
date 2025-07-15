# Test script to verify New-GitCommit verbose and debug output
# This script tests that the preference inheritance works correctly

# Import required modules from local paths
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$modulePath\modules\ScratchCore" -Force
Import-Module -Name "$modulePath\modules\GitTools" -Force

Write-Host "=== Testing New-GitCommit with -Verbose and -Debug ===" -ForegroundColor Cyan

# Test 1: Call New-GitCommit with -Verbose
Write-Host "`nTest 1: Calling New-GitCommit with -Verbose" -ForegroundColor Yellow
try {
    New-GitCommit -CommitMessage "Test commit for verbose output" -Verbose
}
catch {
    Write-Host "Expected error (not in git repo): $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Call New-GitCommit with -Debug
Write-Host "`nTest 2: Calling New-GitCommit with -Debug" -ForegroundColor Yellow
try {
    New-GitCommit -CommitMessage "Test commit for debug output" -Debug
}
catch {
    Write-Host "Expected error (not in git repo): $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Call New-GitCommit with both -Verbose and -Debug
Write-Host "`nTest 3: Calling New-GitCommit with -Verbose and -Debug" -ForegroundColor Yellow
try {
    New-GitCommit -CommitMessage "Test commit for both verbose and debug output" -Verbose -Debug
}
catch {
    Write-Host "Expected error (not in git repo): $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test completed ===" -ForegroundColor Cyan
Write-Host "If you saw verbose and debug output above, the preference inheritance is working correctly." -ForegroundColor Green 