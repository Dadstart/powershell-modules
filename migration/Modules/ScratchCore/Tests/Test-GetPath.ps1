function Test-GetPath {
    <#
    .SYNOPSIS
        Comprehensive tests for the Get-Path function.

    .DESCRIPTION
        Tests all PathType options, edge cases, and cross-platform functionality of the Get-Path function.

    .EXAMPLE
        Test-GetPath
        Runs all tests for the Get-Path function.
#>
    [CmdletBinding()]
    param()

    # Import the module if not already loaded
    if (-not (Get-Module -Name ScratchCore)) {
        Import-Module -Name "$PSScriptRoot\..\ScratchCore.psm1" -Force
    }

    $testResults = @()
    $currentLocation = Get-Location

    Write-Host 'Starting Get-Path function tests...' -ForegroundColor Green
    Write-Host "Current location: $currentLocation" -ForegroundColor Yellow
    Write-Host ''

    # Test 1: Basic PathType tests
    Write-Host 'Test 1: Basic PathType functionality' -ForegroundColor Cyan
    $testPath = 'C:\folder\subfolder\file.txt'
    
    $tests = @(
        @{ PathType = 'Parent'; Expected = 'C:\folder\subfolder' },
        @{ PathType = 'Absolute'; Expected = $testPath },
        @{ PathType = 'Leaf'; Expected = 'file.txt' },
        @{ PathType = 'LeafBase'; Expected = 'file' },
        @{ PathType = 'Extension'; Expected = '.txt' },
        @{ PathType = 'Qualifier'; Expected = 'C:\' },
        @{ PathType = 'NoQualifier'; Expected = 'folder\subfolder\file.txt' }
    )

    foreach ($test in $tests) {
        $result = Get-Path -Path $testPath -PathType $test.PathType
        $passed = $result -eq $test.Expected
        $testResults += [PSCustomObject]@{
            Test     = "PathType $($test.PathType)"
            Input    = $testPath
            Expected = $test.Expected
            Actual   = $result
            Passed   = $passed
        }
        
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        $color = if ($passed) { 'Green' } else { 'Red' }
        Write-Host "  $status - $($test.PathType): $result" -ForegroundColor $color
    }

    # Test 2: Relative path tests
    Write-Host "`nTest 2: Relative path functionality" -ForegroundColor Cyan
    $relativePath = 'subfolder\file.txt'
    $result = Get-Path -Path $relativePath -PathType Absolute
    $currentDir = (Get-Location).Path
    $expected = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($currentDir, $relativePath))
    $passed = $result -eq $expected
    
    $testResults += [PSCustomObject]@{
        Test     = 'Relative to Absolute'
        Input    = $relativePath
        Expected = $expected
        Actual   = $result
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - Relative to Absolute: $result" -ForegroundColor $color

    # Test 3: Multiple path combination
    Write-Host "`nTest 3: Multiple path combination" -ForegroundColor Cyan
    $result = Get-Path -Path 'folder', 'subfolder', 'file.txt' -PathType Absolute
    $currentDir = (Get-Location).Path
    $expected = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($currentDir, 'folder', 'subfolder', 'file.txt'))
    $passed = $result -eq $expected
    
    $testResults += [PSCustomObject]@{
        Test     = 'Multiple Paths'
        Input    = 'folder, subfolder, file.txt'
        Expected = $expected
        Actual   = $result
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - Multiple paths: $result" -ForegroundColor $color

    # Test 4: Directory creation (with cleanup)
    Write-Host "`nTest 4: Directory creation" -ForegroundColor Cyan
    $testDir = 'TestGetPathDir'
    $testSubDir = 'subdir'
    $fullTestPath = Join-Path $currentLocation $testDir
    $fullSubPath = Join-Path $fullTestPath $testSubDir
    
    try {
        # Clean up any existing test directories
        if (Test-Path $fullTestPath) {
            Remove-Item $fullTestPath -Recurse -Force
        }
        
        $result = Get-Path -Path $testDir, $testSubDir -PathType Absolute -Create Directory
        $passed = Test-Path $fullSubPath
        
        $testResults += [PSCustomObject]@{
            Test     = 'Directory Creation'
            Input    = "$testDir\$testSubDir"
            Expected = 'Directory created'
            Actual   = if ($passed) { 'Directory created' } else { 'Directory not created' }
            Passed   = $passed
        }
        
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        $color = if ($passed) { 'Green' } else { 'Red' }
        Write-Host "  $status - Directory creation: $($status.ToLower())" -ForegroundColor $color
    }
    finally {
        # Clean up
        if (Test-Path $fullTestPath) {
            Remove-Item $fullTestPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Test 5: Edge cases
    Write-Host "`nTest 5: Edge cases" -ForegroundColor Cyan
    
    # Test with current directory (single dot)
    $result = Get-Path -Path '.' -PathType Absolute
    $currentDir = (Get-Location).Path
    $expected = [System.IO.Path]::GetFullPath($currentDir)
    $passed = $result -eq $expected
    
    $testResults += [PSCustomObject]@{
        Test     = 'Current Directory'
        Input    = '.'
        Expected = $expected
        Actual   = $result
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - Current directory: $result" -ForegroundColor $color

    # Test with path that has no extension
    $result = Get-Path -Path 'C:\folder\file' -PathType Extension
    $expected = ''
    $passed = $result -eq $expected
    
    $testResults += [PSCustomObject]@{
        Test     = 'No Extension'
        Input    = 'C:\folder\file'
        Expected = $expected
        Actual   = $result
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - No extension: '$result'" -ForegroundColor $color

    # Test 6: Cross-platform path separators
    Write-Host "`nTest 6: Cross-platform path separators" -ForegroundColor Cyan
    
    # Test Unix-style path
    $unixPath = '/home/user/file.txt'
    $result = Get-Path -Path $unixPath -PathType Leaf
    $expected = 'file.txt'
    $passed = $result -eq $expected
    
    $testResults += [PSCustomObject]@{
        Test     = 'Unix Path'
        Input    = $unixPath
        Expected = $expected
        Actual   = $result
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - Unix path: $result" -ForegroundColor $color

    # Test 7: File creation (with cleanup)
    Write-Host "`nTest 7: File creation" -ForegroundColor Cyan
    $testFileDir = 'TestGetPathFileDir'
    $testFileName = 'testfile.txt'
    $fullTestFileDir = Join-Path $currentLocation $testFileDir
    $fullTestFilePath = Join-Path $fullTestFileDir $testFileName
    
    try {
        # Clean up any existing test directories
        if (Test-Path $fullTestFileDir) {
            Remove-Item $fullTestFileDir -Recurse -Force
        }
        
        $result = Get-Path -Path $testFileDir, $testFileName -PathType Absolute -Create File
        $passed = Test-Path $fullTestFilePath -PathType Leaf
        
        $testResults += [PSCustomObject]@{
            Test     = 'File Creation'
            Input    = "$testFileDir\$testFileName"
            Expected = 'File created'
            Actual   = if ($passed) { 'File created' } else { 'File not created' }
            Passed   = $passed
        }
        
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        $color = if ($passed) { 'Green' } else { 'Red' }
        Write-Host "  $status - File creation: $($status.ToLower())" -ForegroundColor $color
    }
    finally {
        # Clean up
        if (Test-Path $fullTestFileDir) {
            Remove-Item $fullTestFileDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Test 8: Path validation
    Write-Host "`nTest 8: Path validation" -ForegroundColor Cyan
    
    # Test file validation with existing file
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $result = Get-Path -Path $tempFile -ValidatePath File
        $passed = $result -eq $tempFile
        
        $testResults += [PSCustomObject]@{
            Test     = 'File Validation (Exists)'
            Input    = $tempFile
            Expected = $tempFile
            Actual   = $result
            Passed   = $passed
        }
        
        $status = if ($passed) { 'PASS' } else { 'FAIL' }
        $color = if ($passed) { 'Green' } else { 'Red' }
        Write-Host "  $status - File validation (exists): $($status.ToLower())" -ForegroundColor $color
    }
    finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }

    # Test file validation with non-existent file
    $nonExistentFile = Join-Path $currentLocation 'nonexistent.txt'
    $result = Get-Path -Path $nonExistentFile -ValidatePath File -ValidationErrorAction Continue
    $passed = $result -eq $null
        
    $testResults += [PSCustomObject]@{
        Test     = 'File Validation (Not Exists)'
        Input    = $nonExistentFile
        Expected = $null
        Actual   = $result
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - File validation (not exists): $($status.ToLower())" -ForegroundColor $color

    # Test 9: Mutual exclusivity between Create and ValidatePath
    Write-Host "`nTest 9: Mutual exclusivity validation" -ForegroundColor Cyan
    
    try {
        $result = Get-Path -Path 'test.txt' -Create File -ValidatePath File
        $passed = $false # Should throw an exception
    }
    catch {
        $passed = $_.Exception.Message -match 'mutually exclusive'
    }
    
    $testResults += [PSCustomObject]@{
        Test     = 'Mutual Exclusivity'
        Input    = 'Create File + ValidatePath File'
        Expected = 'Exception thrown'
        Actual   = if ($passed) { 'Exception thrown' } else { 'No exception' }
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - Mutual exclusivity: $($status.ToLower())" -ForegroundColor $color

    # Test 10: Verbose output
    Write-Host "`nTest 10: Verbose output" -ForegroundColor Cyan
    $verboseOutput = Get-Path -Path 'test.txt' -PathType Absolute -Verbose 4>&1
    $hasVerbose = $verboseOutput -match 'Processing path:'
    $passed = $hasVerbose
    
    $testResults += [PSCustomObject]@{
        Test     = 'Verbose Output'
        Input    = 'test.txt'
        Expected = 'Verbose messages present'
        Actual   = if ($passed) { 'Verbose messages present' } else { 'No verbose messages' }
        Passed   = $passed
    }
    
    $status = if ($passed) { 'PASS' } else { 'FAIL' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host "  $status - Verbose output: $($status.ToLower())" -ForegroundColor $color

    # Summary
    Write-Host "`n" + '='*60 -ForegroundColor White
    Write-Host 'TEST SUMMARY' -ForegroundColor White
    Write-Host '='*60 -ForegroundColor White
    
    $totalTests = $testResults.Count
    $passedTests = ($testResults | Where-Object { $_.Passed }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    
    if ($failedTests -gt 0) {
        Write-Host "`nFAILED TESTS:" -ForegroundColor Red
        $testResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.Test)" -ForegroundColor Red
            Write-Host "    Input: $($_.Input)" -ForegroundColor Gray
            Write-Host "    Expected: $($_.Expected)" -ForegroundColor Gray
            Write-Host "    Actual: $($_.Actual)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n" + '='*60 -ForegroundColor White
    
    return $testResults
}