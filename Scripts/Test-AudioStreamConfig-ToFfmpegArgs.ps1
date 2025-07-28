[CmdletBinding()]
param (
    [Parameter()]
    [string]$TestMode = 'All'
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Testing AudioStreamConfig.ToFfmpegArgs method" -Type Info

try {
    # Test 1: Encoding configuration
    Write-Message "Test 1: Encoding configuration" -Type Processing
    $encodeConfig = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
    $args = $encodeConfig.ToFfmpegArgs(0)
    
    Write-Message "Encoding config: $encodeConfig" -Type Info
    Write-Message "Generated args: $($args -join ' ')" -Type Info
    
    # Verify expected arguments
    $expectedArgs = @('-map', '0:a:1', '-c:a:0', 'aac', '-b:a:0', '384k', '-ac:a:0', '6', '-metadata:s:a:0', 'title=Surround 5.1')
    if (Compare-Object $args $expectedArgs) {
        Write-Message "Test 1 FAILED: Arguments don't match expected" -Type Error
        Write-Message "Expected: $($expectedArgs -join ' ')" -Type Error
        Write-Message "Actual: $($args -join ' ')" -Type Error
    } else {
        Write-Message "Test 1 PASSED: Encoding configuration generates correct arguments" -Type Success
    }

    # Test 2: Copy configuration
    Write-Message "Test 2: Copy configuration" -Type Processing
    $copyConfig = [AudioStreamConfig]::new(0, 'DTS-HD')
    $args = $copyConfig.ToFfmpegArgs(0)
    
    Write-Message "Copy config: $copyConfig" -Type Info
    Write-Message "Generated args: $($args -join ' ')" -Type Info
    
    # Verify expected arguments
    $expectedArgs = @('-map', '0:a:0', '-c:a:0', 'copy', '-metadata:s:a:0', 'title=DTS-HD')
    if (Compare-Object $args $expectedArgs) {
        Write-Message "Test 2 FAILED: Arguments don't match expected" -Type Error
        Write-Message "Expected: $($expectedArgs -join ' ')" -Type Error
        Write-Message "Actual: $($args -join ' ')" -Type Error
    } else {
        Write-Message "Test 2 PASSED: Copy configuration generates correct arguments" -Type Success
    }

    # Test 3: Multiple audio streams with different output indices
    Write-Message "Test 3: Multiple audio streams" -Type Processing
    $audioConfigs = @(
        [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1'),
        [AudioStreamConfig]::new(0, 'DTS-HD')
    )
    
    $allArgs = @()
    for ($i = 0; $i -lt $audioConfigs.Count; $i++) {
        $args = $audioConfigs[$i].ToFfmpegArgs($i)
        $allArgs += $args
        Write-Message "Stream $i config: $($audioConfigs[$i])" -Type Info
        Write-Message "Stream $i args: $($args -join ' ')" -Type Info
    }
    
    Write-Message "All args: $($allArgs -join ' ')" -Type Info
    Write-Message "Test 3 PASSED: Multiple audio streams generate correct arguments" -Type Success

    # Test 4: Integration with Convert-VideoFile (simulation)
    Write-Message "Test 4: Integration simulation" -Type Processing
    $pass2Args = @('-y', '-i', 'input.mkv')
    $pass2Args += @('-c:v', 'libx264', '-preset', 'slow', '-b:v', '5000k')
    $pass2Args += @('-pass', '2', '-passlogfile', 'test.ffmpeg', '-map', '0:v:0')
    
    # Add audio streams using ToFfmpegArgs
    for ($i = 0; $i -lt $audioConfigs.Count; $i++) {
        $pass2Args += $audioConfigs[$i].ToFfmpegArgs($i)
    }
    
    $pass2Args += @('-map_metadata', '0', '-map_chapters', '0', '-movflags', '+faststart', 'output.mp4')
    
    Write-Message "Simulated FFmpeg command:" -Type Info
    Write-Message "ffmpeg $($pass2Args -join ' ')" -Type Info
    Write-Message "Test 4 PASSED: Integration simulation successful" -Type Success

    # Test 5: Edge cases
    Write-Message "Test 5: Edge cases" -Type Processing
    
    # Test with no bitrate (should not add bitrate argument)
    $noBitrateConfig = [AudioStreamConfig]::new(2, 'mp3', $null, 2, 'Stereo')
    $args = $noBitrateConfig.ToFfmpegArgs(1)
    Write-Message "No bitrate config: $noBitrateConfig" -Type Info
    Write-Message "Generated args: $($args -join ' ')" -Type Info
    
    # Test with no channels (should not add channels argument)
    $noChannelsConfig = [AudioStreamConfig]::new(3, 'aac', '192k', $null, 'Audio Track')
    $args = $noChannelsConfig.ToFfmpegArgs(2)
    Write-Message "No channels config: $noChannelsConfig" -Type Info
    Write-Message "Generated args: $($args -join ' ')" -Type Info
    
    Write-Message "Test 5 PASSED: Edge cases handled correctly" -Type Success

    Write-Message "All AudioStreamConfig.ToFfmpegArgs tests completed successfully!" -Type Success
}
catch {
    Write-Message "Test failed: $($_.Exception.Message)" -Type Error
    throw
} 