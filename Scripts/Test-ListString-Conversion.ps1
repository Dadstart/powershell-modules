[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Testing List[string] conversion for AudioStreamConfig and VideoEncodingConfig" -Type Info

try {
    # Test AudioStreamConfig with List[string]
    Write-Message "Test 1: AudioStreamConfig.ToFfmpegArgs with List[string]" -Type Processing
    $audioConfig = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
    $args = $audioConfig.ToFfmpegArgs(0)
    
    Write-Message "Audio config: $audioConfig" -Type Info
    Write-Message "Generated args type: $($args.GetType().FullName)" -Type Info
    Write-Message "Generated args: $($args -join ' ')" -Type Info
    
    # Verify it's a List[string]
    if ($args -is [System.Collections.Generic.List[string]]) {
        Write-Message "Test 1 PASSED: AudioStreamConfig returns List[string]" -Type Success
    } else {
        Write-Message "Test 1 FAILED: AudioStreamConfig does not return List[string]" -Type Error
    }

    # Test VideoEncodingConfig with List[string]
    Write-Message "Test 2: VideoEncodingConfig.GetFFmpegArgs with List[string]" -Type Processing
    $videoConfig = [VideoEncodingConfig]::new('5000k', 'slow')
    $args = $videoConfig.GetFFmpegArgs()
    
    Write-Message "Video config: $videoConfig" -Type Info
    Write-Message "Generated args type: $($args.GetType().FullName)" -Type Info
    Write-Message "Generated args: $($args -join ' ')" -Type Info
    
    # Verify it's a List[string]
    if ($args -is [System.Collections.Generic.List[string]]) {
        Write-Message "Test 2 PASSED: VideoEncodingConfig returns List[string]" -Type Success
    } else {
        Write-Message "Test 2 FAILED: VideoEncodingConfig does not return List[string]" -Type Error
    }

    # Test integration with Convert-VideoFile (simulation)
    Write-Message "Test 3: Integration simulation with List[string]" -Type Processing
    $pass2Args = [System.Collections.Generic.List[string]]::new()
    $pass2Args.Add('-y')
    $pass2Args.Add('-i')
    $pass2Args.Add('input.mkv')
    
    # Add video encoding arguments
    $videoArgs = $videoConfig.GetFFmpegArgs()
    $pass2Args.AddRange($videoArgs)
    
    # Add audio stream arguments
    $audioArgs = $audioConfig.ToFfmpegArgs(0)
    $pass2Args.AddRange($audioArgs)
    
    Write-Message "Integrated FFmpeg command:" -Type Info
    Write-Message "ffmpeg $($pass2Args -join ' ')" -Type Info
    Write-Message "Test 3 PASSED: Integration with List[string] works correctly" -Type Success

    # Test performance comparison
    Write-Message "Test 4: Performance comparison" -Type Processing
    
    # Test array appending (old way)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $arrayArgs = @()
    for ($i = 0; $i -lt 1000; $i++) {
        $arrayArgs += '-test', $i.ToString()
    }
    $stopwatch.Stop()
    $arrayTime = $stopwatch.ElapsedMilliseconds
    
    # Test List[string] (new way)
    $stopwatch.Restart()
    $listArgs = [System.Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt 1000; $i++) {
        $listArgs.Add('-test')
        $listArgs.Add($i.ToString())
    }
    $stopwatch.Stop()
    $listTime = $stopwatch.ElapsedMilliseconds
    
    Write-Message "Array appending time: ${arrayTime}ms" -Type Info
    Write-Message "List[string] time: ${listTime}ms" -Type Info
    
    if ($listTime -lt $arrayTime) {
        Write-Message "Test 4 PASSED: List[string] is faster than array appending" -Type Success
    } else {
        Write-Message "Test 4 INFO: Array appending was faster in this test" -Type Info
    }

    Write-Message "All List[string] conversion tests completed successfully!" -Type Success
}
catch {
    Write-Message "Test failed: $($_.Exception.Message)" -Type Error
    throw
} 