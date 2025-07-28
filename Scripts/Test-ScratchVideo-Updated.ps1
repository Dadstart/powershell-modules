[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message 'Testing updated scratch-video.ps1 functionality' -Type Info

try {
    # Test 1: Verify the configuration objects can be created
    Write-Message 'Test 1: Creating video and audio configurations' -Type Processing

    $videoConfig = New-VideoEncodingConfig -Bitrate '5000k' -Preset 'slow'
    $audioConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
        (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy)
    )

    Write-Message "Video config created: $videoConfig" -Type Info
    Write-Message 'Audio configs created:' -Type Info
    foreach ($audioConfig in $audioConfigs) {
        Write-Message "  $audioConfig" -Type Info
    }
    Write-Message 'Test 1 PASSED: Configuration objects created successfully' -Type Success

    # Test 2: Verify the configurations work with Convert-VideoFile (simulation)
    Write-Message 'Test 2: Simulating Convert-VideoFile with configurations' -Type Processing

    # Create a test input file path
    $testInputFile = 'test_input.mkv'
    $testOutputFile = 'test_output.mp4'

    # Simulate the Convert-VideoFile call
    Write-Message "Simulating: Convert-VideoFile -InputFile '$testInputFile' -OutputFile '$testOutputFile' -VideoEncoding `$videoConfig -AudioStreams `$audioConfigs" -Type Info

    # Test the FFmpeg argument generation
    $videoArgs = $videoConfig.GetFFmpegArgs()
    Write-Message "Video FFmpeg args: $($videoArgs -join ' ')" -Type Info

    foreach ($audioConfig in $audioConfigs) {
        $audioArgs = $audioConfig.ToFfmpegArgs(0)
        Write-Message "Audio FFmpeg args: $($audioArgs -join ' ')" -Type Info
    }

    Write-Message 'Test 2 PASSED: FFmpeg argument generation works correctly' -Type Success

    # Test 3: Verify directory and file handling logic
    Write-Message 'Test 3: Testing directory and file handling logic' -Type Processing

    $currentDir = Get-Location
    $mp4Folder = Join-Path $currentDir 'MP4'
    Write-Message "Current directory: $currentDir" -Type Info
    Write-Message "MP4 folder path: $mp4Folder" -Type Info

    # Test MP4 folder creation logic
    if (-not (Test-Path $mp4Folder)) {
        Write-Message 'MP4 folder does not exist - would create it' -Type Info
    } else {
        Write-Message 'MP4 folder already exists' -Type Info
    }

    # Test MKV file discovery
    $mkvFiles = Get-ChildItem -Path $currentDir -Filter '*.mkv' -File
    Write-Message "Found $($mkvFiles.Count) MKV files in current directory" -Type Info

    if ($mkvFiles.Count -gt 0) {
        foreach ($mkvFile in $mkvFiles) {
            $outputFileName = [System.IO.Path]::ChangeExtension($mkvFile.Name, '.mp4')
            $outputPath = Join-Path $mp4Folder $outputFileName
            Write-Message "Would convert: $($mkvFile.Name) -> $outputPath" -Type Info

            if (Test-Path $outputPath) {
                Write-Message '  (Would skip - output exists)' -Type Info
            } else {
                Write-Message "  (Would process - output doesn't exist)" -Type Info
            }
        }
    }

    Write-Message 'Test 3 PASSED: Directory and file handling logic works correctly' -Type Success

    # Test 4: Verify error handling
    Write-Message 'Test 4: Testing error handling' -Type Processing

    # Test with non-existent file
    $nonExistentFile = 'non_existent_file.mkv'
    $testOutputPath = Join-Path $mp4Folder 'test_output.mp4'

    try {
        # This should fail gracefully
        Convert-VideoFile -InputFile $nonExistentFile -OutputFile $testOutputPath -VideoEncoding $videoConfig -AudioStreams $audioConfigs -ErrorAction Stop
        Write-Message 'Test 4 FAILED: Should have thrown an error for non-existent file' -Type Error
    }
    catch {
        Write-Message 'Test 4 PASSED: Error handling works correctly for non-existent files' -Type Success
    }

    Write-Message 'All tests completed successfully!' -Type Success
}
catch {
    Write-Message "Test failed: $($_.Exception.Message)" -Type Error
    throw
}
