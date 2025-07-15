function Test-SafeFileRename {
    # Test script for Invoke-SafeFileRename script
    # This script demonstrates various scenarios for safe file renaming

    $scriptPath = $PSScriptRoot + '\Invoke-SafeFileRename.ps1'

    # Create a test directory
    $testDir = '.\TestRename'
    if (Test-Path $testDir) {
        Remove-Item $testDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $testDir | Out-Null

    Write-Host '=== Safe File Rename Test Script ===' -ForegroundColor Green
    Write-Host "Test directory: $((Get-Location).Path)\$testDir" -ForegroundColor Yellow

    # Create test files
    $testFiles = @(
        'movie1.mp4',
        'movie2.avi', 
        'document1.txt',
        'image1.jpg',
        'existing_target.mp4'
    )

    foreach ($file in $testFiles) {
        $filePath = Join-Path $testDir $file
        "Test content for $file" | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host "Created: $file" -ForegroundColor Gray
    }

    Write-Host "`n=== Test 1: Simple Rename (Dry Run) ===" -ForegroundColor Cyan
    & $scriptPath -FileMappings @{'movie1' = 'newmovie1'; 'movie2' = 'newmovie2' } -WorkingDirectory $testDir -DryRun -Verbose

    Write-Host "`n=== Test 2: Rename with Extension Preservation (Dry Run) ===" -ForegroundColor Cyan
    & $scriptPath -FileMappings @{'movie1' = 'renamed_movie'; 'document1' = 'renamed_doc' } -WorkingDirectory $testDir -DryRun -Verbose

    Write-Host "`n=== Test 3: Rename with Extension Change (Dry Run) ===" -ForegroundColor Cyan
    & $scriptPath -FileMappings @{'movie1' = 'newmovie1.mkv'; 'image1' = 'newimage1.png' } -WorkingDirectory $testDir -DryRun -Verbose

    Write-Host "`n=== Test 4: Rename with Target Conflict (Dry Run) ===" -ForegroundColor Cyan
    & $scriptPath -FileMappings @{'movie1' = 'existing_target' } -WorkingDirectory $testDir -DryRun -Verbose

    Write-Host "`n=== Test 5: Circular Rename (Dry Run) ===" -ForegroundColor Cyan
    & $scriptPath -FileMappings @{'movie1' = 'movie2'; 'movie2' = 'movie1' } -WorkingDirectory $testDir -DryRun -Verbose

    Write-Host "`n=== Test 6: Actual Simple Rename ===" -ForegroundColor Cyan
    & $scriptPath -FileMappings @{'movie1' = 'newmovie1'; 'movie2' = 'newmovie2' } -WorkingDirectory $testDir -Verbose

    Write-Host "`n=== Test 7: Actual Rename with Target Conflict ===" -ForegroundColor Cyan
    # First, create a file that will conflict
    'Conflict content' | Out-File -FilePath (Join-Path $testDir 'newmovie1.mp4') -Encoding UTF8
    & $scriptPath -FileMappings @{'document1' = 'newmovie1' } -WorkingDirectory $testDir -Verbose

    Write-Host "`n=== Final Directory Contents ===" -ForegroundColor Green
    Get-ChildItem $testDir | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor White }

    Write-Host "`n=== Cleanup ===" -ForegroundColor Yellow
    Write-Host "To clean up test files, run: Remove-Item '$testDir' -Recurse -Force" -ForegroundColor Gray 
}