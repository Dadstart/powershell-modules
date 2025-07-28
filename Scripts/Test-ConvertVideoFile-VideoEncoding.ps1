[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Testing Convert-VideoFile video encoding configurations" -Type Info
Write-Message "Input: $InputFile" -Type Info
Write-Message "Output Directory: $OutputDirectory" -Type Info

try {
    # Test 1: Default VBR configuration (legacy parameters)
    Write-Message "Test 1: Default VBR configuration (legacy parameters)" -Type Processing
    $outputFile1 = Join-Path $OutputDirectory "test1-default-vbr.mp4"
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile1 -Verbose
    Write-Message "Test 1 completed successfully!" -Type Success
    
    # Test 2: VBR with custom bitrate and preset
    Write-Message "Test 2: VBR with custom bitrate and preset" -Type Processing
    $outputFile2 = Join-Path $OutputDirectory "test2-custom-vbr.mp4"
    $vbrConfig = New-VideoEncodingConfig -Bitrate '8000k' -Preset 'veryslow'
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile2 -VideoEncoding $vbrConfig -Verbose
    Write-Message "Test 2 completed successfully!" -Type Success
    
    # Test 3: CRF encoding (quality-based)
    Write-Message "Test 3: CRF encoding (quality-based)" -Type Processing
    $outputFile3 = Join-Path $OutputDirectory "test3-crf.mp4"
    $crfConfig = New-VideoEncodingConfig -CRF 23 -Preset 'slow'
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile3 -VideoEncoding $crfConfig -Verbose
    Write-Message "Test 3 completed successfully!" -Type Success
    
    # Test 4: High-quality CRF encoding
    Write-Message "Test 4: High-quality CRF encoding" -Type Processing
    $outputFile4 = Join-Path $OutputDirectory "test4-high-quality-crf.mp4"
    $highQualityConfig = New-VideoEncodingConfig -CRF 18 -Preset 'veryslow'
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile4 -VideoEncoding $highQualityConfig -Verbose
    Write-Message "Test 4 completed successfully!" -Type Success
    
    # Test 5: CQP encoding (direct quality control)
    Write-Message "Test 5: CQP encoding (direct quality control)" -Type Processing
    $outputFile5 = Join-Path $OutputDirectory "test5-cqp.mp4"
    $cqpConfig = New-VideoEncodingConfig -QP 23 -Preset 'slow' -Mode 'CQP'
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile5 -VideoEncoding $cqpConfig -Verbose
    Write-Message "Test 5 completed successfully!" -Type Success
    
    # Test 6: Fast encoding with CRF
    Write-Message "Test 6: Fast encoding with CRF" -Type Processing
    $outputFile6 = Join-Path $OutputDirectory "test6-fast-crf.mp4"
    $fastConfig = New-VideoEncodingConfig -CRF 28 -Preset 'ultrafast'
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile6 -VideoEncoding $fastConfig -Verbose
    Write-Message "Test 6 completed successfully!" -Type Success
    
    # Test 7: Profile and level configuration
    Write-Message "Test 7: Profile and level configuration" -Type Processing
    $outputFile7 = Join-Path $OutputDirectory "test7-profile-level.mp4"
    $profileConfig = New-VideoEncodingConfig -CRF 23 -Preset 'slow' -Profile 'high' -Level '4.1'
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile7 -VideoEncoding $profileConfig -Verbose
    Write-Message "Test 7 completed successfully!" -Type Success
    
    # Test 8: Pipeline with video encoding configuration
    Write-Message "Test 8: Pipeline with video encoding configuration" -Type Processing
    $outputFile8 = Join-Path $OutputDirectory "test8-pipeline-crf.mp4"
    $pipelineConfig = New-VideoEncodingConfig -CRF 25 -Preset 'medium'
    @($InputFile) | Convert-VideoFile -OutputFile $outputFile8 -VideoEncoding $pipelineConfig -Verbose
    Write-Message "Test 8 completed successfully!" -Type Success
    
    # Test 9: Different CRF values comparison
    Write-Message "Test 9: Different CRF values comparison" -Type Processing
    $crfValues = @(18, 23, 28, 35)
    foreach ($crf in $crfValues) {
        $outputFile = Join-Path $OutputDirectory "test9-crf-$crf.mp4"
        $config = New-VideoEncodingConfig -CRF $crf -Preset 'slow'
        Write-Message "Testing CRF $crf..." -Type Info
        Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile -VideoEncoding $config -Verbose
    }
    Write-Message "Test 9 completed successfully!" -Type Success
    
    # Test 10: Different bitrates comparison
    Write-Message "Test 10: Different bitrates comparison" -Type Processing
    $bitrates = @('2000k', '5000k', '8000k')
    foreach ($bitrate in $bitrates) {
        $outputFile = Join-Path $OutputDirectory "test10-vbr-$bitrate.mp4"
        $config = New-VideoEncodingConfig -Bitrate $bitrate -Preset 'slow'
        Write-Message "Testing bitrate $bitrate..." -Type Info
        Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile -VideoEncoding $config -Verbose
    }
    Write-Message "Test 10 completed successfully!" -Type Success
    
    # Test 11: Direct VideoEncodingConfig constructor usage
    Write-Message "Test 11: Direct VideoEncodingConfig constructor usage" -Type Processing
    $outputFile11 = Join-Path $OutputDirectory "test11-direct-constructor.mp4"
    $directConfig = [VideoEncodingConfig]::new(23, 'slow')
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile11 -VideoEncoding $directConfig -Verbose
    Write-Message "Test 11 completed successfully!" -Type Success
    
    # Test 12: VideoEncodingConfig with audio configuration
    Write-Message "Test 12: VideoEncodingConfig with audio configuration" -Type Processing
    $outputFile12 = Join-Path $OutputDirectory "test12-video-audio-config.mp4"
    $videoConfig = New-VideoEncodingConfig -CRF 23 -Preset 'slow'
    $audioConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
        (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy)
    )
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile12 -VideoEncoding $videoConfig -AudioStreams $audioConfigs -Verbose
    Write-Message "Test 12 completed successfully!" -Type Success
    
    Write-Message "All video encoding configuration tests completed successfully!" -Type Success
    
    # Summary of file sizes
    Write-Message "`nFile size comparison:" -Type Info
    $testFiles = Get-ChildItem -Path $OutputDirectory -Filter "test*.mp4" | Sort-Object Name
    foreach ($file in $testFiles) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        Write-Message "  $($file.Name): $sizeMB MB" -Type Info
    }
}
catch {
    Write-Message "Video encoding configuration test failed: $($_.Exception.Message)" -Type Error
    throw
} 