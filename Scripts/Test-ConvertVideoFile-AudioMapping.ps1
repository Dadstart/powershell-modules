[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Testing Convert-VideoFile audio mapping functionality" -Type Info
Write-Message "Input: $InputFile" -Type Info
Write-Message "Output: $OutputFile" -Type Info

try {
    # Test 1: Default audio mapping (stream 1 -> primary, stream 0 -> secondary)
    Write-Message "Test 1: Default audio mapping" -Type Processing
    Convert-VideoFile -InputFile $InputFile -OutputFile $OutputFile -Verbose
    
    Write-Message "Test 1 completed successfully!" -Type Success
    
    # Test 2: Custom audio mapping (stream 2 -> primary, stream 1 -> secondary)
    Write-Message "Test 2: Custom audio mapping (stream 2 -> primary, stream 1 -> secondary)" -Type Processing
    $outputFile2 = [System.IO.Path]::ChangeExtension($OutputFile, '.custom.mp4')
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile2 -PrimaryAudioStream 2 -SecondaryAudioStream 1 -Verbose
    
    Write-Message "Test 2 completed successfully!" -Type Success
    
    # Test 3: Custom audio titles
    Write-Message "Test 3: Custom audio titles" -Type Processing
    $outputFile3 = [System.IO.Path]::ChangeExtension($OutputFile, '.titles.mp4')
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile3 -PrimaryAudioTitle "English 5.1" -SecondaryAudioTitle "English DTS-HD" -Verbose
    
    Write-Message "Test 3 completed successfully!" -Type Success
    
    # Test 4: Pipeline with custom audio mapping
    Write-Message "Test 4: Pipeline with custom audio mapping" -Type Processing
    $outputFile4 = [System.IO.Path]::ChangeExtension($OutputFile, '.pipeline.mp4')
    @($InputFile) | Convert-VideoFile -OutputFile $outputFile4 -PrimaryAudioStream 2 -SecondaryAudioStream 1 -Verbose
    
    Write-Message "Test 4 completed successfully!" -Type Success
    
    Write-Message "All audio mapping tests completed successfully!" -Type Success
}
catch {
    Write-Message "Audio mapping test failed: $($_.Exception.Message)" -Type Error
    throw
} 