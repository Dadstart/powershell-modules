[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputDirectory,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Testing Convert-VideoFile pipeline functionality" -Type Info
Write-Message "Input Directory: $InputDirectory" -Type Info
Write-Message "Output File: $OutputFile" -Type Info

try {
    # Test 1: Pipeline with multiple files
    Write-Message "Test 1: Pipeline with multiple files" -Type Processing
    $inputFiles = Get-ChildItem -Path $InputDirectory -Filter "*.mkv" | Select-Object -First 2
    if ($inputFiles.Count -eq 0) {
        Write-Message "No MKV files found in directory. Creating test files..." -Type Warning
        # Create some test files for demonstration
        $testFile1 = Join-Path $InputDirectory "test1.mkv"
        $testFile2 = Join-Path $InputDirectory "test2.mkv"
        "Test content" | Out-File -FilePath $testFile1 -Encoding UTF8
        "Test content" | Out-File -FilePath $testFile2 -Encoding UTF8
        $inputFiles = @($testFile1, $testFile2)
    }
    
    Write-Message "Found $($inputFiles.Count) files to process" -Type Info
    $inputFiles.FullName | Convert-VideoFile -OutputFile $OutputFile -Verbose
    
    Write-Message "Test 1 completed successfully!" -Type Success
    
    # Test 2: Pipeline with Get-ChildItem
    Write-Message "Test 2: Pipeline with Get-ChildItem" -Type Processing
    Get-ChildItem -Path $InputDirectory -Filter "*.mkv" | 
        Convert-VideoFile -OutputFile $OutputFile -Verbose
    
    Write-Message "Test 2 completed successfully!" -Type Success
    
    # Test 3: Pipeline with array
    Write-Message "Test 3: Pipeline with array" -Type Processing
    @("file1.mkv", "file2.mkv") | 
        Convert-VideoFile -OutputFile $OutputFile -Verbose
    
    Write-Message "Test 3 completed successfully!" -Type Success
    
    Write-Message "All pipeline tests completed successfully!" -Type Success
}
catch {
    Write-Message "Pipeline test failed: $($_.Exception.Message)" -Type Error
    throw
} 