[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Testing Convert-VideoFile modular audio configuration" -Type Info
Write-Message "Input: $InputFile" -Type Info
Write-Message "Output: $OutputFile" -Type Info

try {
    # Test 1: Default configuration (no AudioStreams parameter)
    Write-Message "Test 1: Default audio configuration" -Type Processing
    Convert-VideoFile -InputFile $InputFile -OutputFile $OutputFile -Verbose
    Write-Message "Test 1 completed successfully!" -Type Success
    
    # Test 2: Custom audio configuration with multiple streams
    Write-Message "Test 2: Custom audio configuration with multiple streams" -Type Processing
    $outputFile2 = [System.IO.Path]::ChangeExtension($OutputFile, '.custom.mp4')
    $audioConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
        (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy),
        (New-AudioStreamConfig -InputStreamIndex 2 -Codec 'aac' -Bitrate '192k' -Channels 2 -Title 'Stereo Commentary')
    )
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile2 -AudioStreams $audioConfigs -Verbose
    Write-Message "Test 2 completed successfully!" -Type Success
    
    # Test 3: Single audio stream (encode only)
    Write-Message "Test 3: Single audio stream (encode only)" -Type Processing
    $outputFile3 = [System.IO.Path]::ChangeExtension($OutputFile, '.single.mp4')
    $singleAudioConfig = @(
        (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '256k' -Channels 2 -Title 'Stereo')
    )
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile3 -AudioStreams $singleAudioConfig -Verbose
    Write-Message "Test 3 completed successfully!" -Type Success
    
    # Test 4: Copy only configuration
    Write-Message "Test 4: Copy only configuration" -Type Processing
    $outputFile4 = [System.IO.Path]::ChangeExtension($OutputFile, '.copy.mp4')
    $copyConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 0 -Title 'Original Audio' -Copy),
        (New-AudioStreamConfig -InputStreamIndex 1 -Title 'Secondary Audio' -Copy)
    )
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile4 -AudioStreams $copyConfigs -Verbose
    Write-Message "Test 4 completed successfully!" -Type Success
    
    # Test 5: Pipeline with custom audio configuration
    Write-Message "Test 5: Pipeline with custom audio configuration" -Type Processing
    $outputFile5 = [System.IO.Path]::ChangeExtension($OutputFile, '.pipeline.mp4')
    $pipelineConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 2 -Codec 'aac' -Bitrate '320k' -Channels 6 -Title 'Pipeline Test'),
        (New-AudioStreamConfig -InputStreamIndex 0 -Title 'Pipeline Copy' -Copy)
    )
    @($InputFile) | Convert-VideoFile -OutputFile $outputFile5 -AudioStreams $pipelineConfigs -Verbose
    Write-Message "Test 5 completed successfully!" -Type Success
    
    # Test 6: Different codecs
    Write-Message "Test 6: Different codecs" -Type Processing
    $outputFile6 = [System.IO.Path]::ChangeExtension($OutputFile, '.codecs.mp4')
    $codecConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'mp3' -Bitrate '192k' -Channels 2 -Title 'MP3 Stereo'),
        (New-AudioStreamConfig -InputStreamIndex 0 -Codec 'ac3' -Bitrate '384k' -Channels 6 -Title 'AC3 Surround')
    )
    Convert-VideoFile -InputFile $InputFile -OutputFile $outputFile6 -AudioStreams $codecConfigs -Verbose
    Write-Message "Test 6 completed successfully!" -Type Success
    
    Write-Message "All modular audio configuration tests completed successfully!" -Type Success
}
catch {
    Write-Message "Modular audio configuration test failed: $($_.Exception.Message)" -Type Error
    throw
} 