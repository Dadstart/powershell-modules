[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "AudioStreamConfig Class Examples" -Type Info
Write-Message "=================================" -Type Info

try {
    # Example 1: Basic encoding configuration
    Write-Message "Example 1: Basic encoding configuration" -Type Processing
    $encodeConfig = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
    Write-Message "Configuration: $encodeConfig" -Type Info
    Write-Message "InputStreamIndex: $($encodeConfig.InputStreamIndex)" -Type Verbose
    Write-Message "Codec: $($encodeConfig.Codec)" -Type Verbose
    Write-Message "Bitrate: $($encodeConfig.Bitrate)" -Type Verbose
    Write-Message "Channels: $($encodeConfig.Channels)" -Type Verbose
    Write-Message "Title: $($encodeConfig.Title)" -Type Verbose
    Write-Message "Copy: $($encodeConfig.Copy)" -Type Verbose
    
    # Example 2: Copy configuration
    Write-Message "`nExample 2: Copy configuration" -Type Processing
    $copyConfig = [AudioStreamConfig]::new(0, 'DTS-HD')
    Write-Message "Configuration: $copyConfig" -Type Info
    Write-Message "InputStreamIndex: $($copyConfig.InputStreamIndex)" -Type Verbose
    Write-Message "Codec: $($copyConfig.Codec)" -Type Verbose
    Write-Message "Title: $($copyConfig.Title)" -Type Verbose
    Write-Message "Copy: $($copyConfig.Copy)" -Type Verbose
    
    # Example 3: Multiple configurations
    Write-Message "`nExample 3: Multiple configurations" -Type Processing
    $configs = @(
        [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1'),
        [AudioStreamConfig]::new(0, 'DTS-HD'),
        [AudioStreamConfig]::new(2, 'aac', '192k', 2, 'Stereo Commentary')
    )
    
    Write-Message "Multiple configurations:" -Type Info
    foreach ($config in $configs) {
        Write-Message "  $config" -Type Info
    }
    
    # Example 4: Different codecs and bitrates
    Write-Message "`nExample 4: Different codecs and bitrates" -Type Processing
    $codecExamples = @(
        [AudioStreamConfig]::new(0, 'aac', '256k', 2, 'AAC Stereo'),
        [AudioStreamConfig]::new(1, 'mp3', '192k', 2, 'MP3 Stereo'),
        [AudioStreamConfig]::new(2, 'ac3', '384k', 6, 'AC3 Surround'),
        [AudioStreamConfig]::new(3, 'opus', '128k', 2, 'Opus Stereo')
    )
    
    Write-Message "Different codec examples:" -Type Info
    foreach ($config in $codecExamples) {
        Write-Message "  $config" -Type Info
    }
    
    # Example 5: Channel configurations
    Write-Message "`nExample 5: Channel configurations" -Type Processing
    $channelExamples = @(
        [AudioStreamConfig]::new(0, 'aac', '128k', 1, 'Mono'),
        [AudioStreamConfig]::new(1, 'aac', '256k', 2, 'Stereo'),
        [AudioStreamConfig]::new(2, 'aac', '384k', 6, '5.1 Surround'),
        [AudioStreamConfig]::new(3, 'aac', '512k', 8, '7.1 Surround')
    )
    
    Write-Message "Channel configuration examples:" -Type Info
    foreach ($config in $channelExamples) {
        Write-Message "  $config" -Type Info
    }
    
    # Example 6: Using with New-AudioStreamConfig function
    Write-Message "`nExample 6: Using New-AudioStreamConfig function" -Type Processing
    $functionConfigs = @(
        (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
        (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy),
        (New-AudioStreamConfig -InputStreamIndex 2 -Codec 'mp3' -Bitrate '192k' -Channels 2 -Title 'MP3 Stereo')
    )
    
    Write-Message "Function-created configurations:" -Type Info
    foreach ($config in $functionConfigs) {
        Write-Message "  $config" -Type Info
    }
    
    # Example 7: Validation and error handling
    Write-Message "`nExample 7: Validation and error handling" -Type Processing
    try {
        # This should work
        $validConfig = [AudioStreamConfig]::new(0, 'aac', '256k', 2, 'Valid Config')
        Write-Message "Valid configuration created: $validConfig" -Type Success
        
        # Show property access
        Write-Message "Property access examples:" -Type Info
        Write-Message "  InputStreamIndex: $($validConfig.InputStreamIndex)" -Type Verbose
        Write-Message "  Codec: $($validConfig.Codec)" -Type Verbose
        Write-Message "  Copy: $($validConfig.Copy)" -Type Verbose
    }
    catch {
        Write-Message "Error creating configuration: $($_.Exception.Message)" -Type Error
    }
    
    # Example 8: Integration with Convert-VideoFile
    Write-Message "`nExample 8: Integration with Convert-VideoFile" -Type Processing
    Write-Message "Example audio configurations for Convert-VideoFile:" -Type Info
    
    # Default configuration (what Convert-VideoFile uses when no AudioStreams specified)
    $defaultConfigs = @(
        [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1'),
        [AudioStreamConfig]::new(0, 'DTS-HD')
    )
    Write-Message "Default configuration:" -Type Info
    foreach ($config in $defaultConfigs) {
        Write-Message "  $config" -Type Info
    }
    
    # Custom configuration
    $customConfigs = @(
        [AudioStreamConfig]::new(2, 'aac', '320k', 6, 'Primary Audio'),
        [AudioStreamConfig]::new(1, 'DTS-HD'),
        [AudioStreamConfig]::new(3, 'aac', '192k', 2, 'Commentary')
    )
    Write-Message "Custom configuration:" -Type Info
    foreach ($config in $customConfigs) {
        Write-Message "  $config" -Type Info
    }
    
    Write-Message "`nAll AudioStreamConfig examples completed successfully!" -Type Success
}
catch {
    Write-Message "AudioStreamConfig examples failed: $($_.Exception.Message)" -Type Error
    throw
} 