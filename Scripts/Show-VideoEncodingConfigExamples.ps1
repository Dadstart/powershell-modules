[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "VideoEncodingConfig Class Examples" -Type Info
Write-Message "===================================" -Type Info

try {
    # Example 1: VBR encoding configuration
    Write-Message "Example 1: VBR encoding configuration" -Type Processing
    $vbrConfig = [VideoEncodingConfig]::new('5000k', 'slow')
    Write-Message "Configuration: $vbrConfig" -Type Info
    Write-Message "EncodingMode: $($vbrConfig.EncodingMode)" -Type Verbose
    Write-Message "Bitrate: $($vbrConfig.Bitrate)" -Type Verbose
    Write-Message "Preset: $($vbrConfig.Preset)" -Type Verbose
    Write-Message "FFmpeg Args: $($vbrConfig.GetFFmpegArgs() -join ' ')" -Type Verbose
    
    # Example 2: CRF encoding configuration
    Write-Message "`nExample 2: CRF encoding configuration" -Type Processing
    $crfConfig = [VideoEncodingConfig]::new(23, 'slow')
    Write-Message "Configuration: $crfConfig" -Type Info
    Write-Message "EncodingMode: $($crfConfig.EncodingMode)" -Type Verbose
    Write-Message "CRF: $($crfConfig.CRF)" -Type Verbose
    Write-Message "Preset: $($crfConfig.Preset)" -Type Verbose
    Write-Message "FFmpeg Args: $($crfConfig.GetFFmpegArgs() -join ' ')" -Type Verbose
    
    # Example 3: CQP encoding configuration
    Write-Message "`nExample 3: CQP encoding configuration" -Type Processing
    $cqpConfig = [VideoEncodingConfig]::new(23, 'slow', 'CQP')
    Write-Message "Configuration: $cqpConfig" -Type Info
    Write-Message "EncodingMode: $($cqpConfig.EncodingMode)" -Type Verbose
    Write-Message "QP: $($cqpConfig.QP)" -Type Verbose
    Write-Message "Preset: $($cqpConfig.Preset)" -Type Verbose
    Write-Message "FFmpeg Args: $($cqpConfig.GetFFmpegArgs() -join ' ')" -Type Verbose
    
    # Example 4: High-quality VBR configuration
    Write-Message "`nExample 4: High-quality VBR configuration" -Type Processing
    $highQualityVbr = [VideoEncodingConfig]::new('8000k', 'veryslow', 'high', '4.1')
    Write-Message "Configuration: $highQualityVbr" -Type Info
    Write-Message "Profile: $($highQualityVbr.Profile)" -Type Verbose
    Write-Message "Level: $($highQualityVbr.Level)" -Type Verbose
    Write-Message "FFmpeg Args: $($highQualityVbr.GetFFmpegArgs() -join ' ')" -Type Verbose
    
    # Example 5: Different CRF values
    Write-Message "`nExample 5: Different CRF values" -Type Processing
    $crfValues = @(18, 23, 28, 35)
    foreach ($crf in $crfValues) {
        $config = [VideoEncodingConfig]::new($crf, 'slow')
        Write-Message "CRF $crf: $config" -Type Info
    }
    
    # Example 6: Different bitrates
    Write-Message "`nExample 6: Different bitrates" -Type Processing
    $bitrates = @('2000k', '5000k', '8000k')
    foreach ($bitrate in $bitrates) {
        $config = [VideoEncodingConfig]::new($bitrate, 'slow')
        Write-Message "Bitrate $bitrate: $config" -Type Info
    }
    
    # Example 7: Different presets
    Write-Message "`nExample 7: Different presets" -Type Processing
    $presets = @('ultrafast', 'fast', 'medium', 'slow', 'veryslow')
    foreach ($preset in $presets) {
        $config = [VideoEncodingConfig]::new(23, $preset)
        Write-Message "Preset $preset: $config" -Type Info
    }
    
    # Example 8: Using New-VideoEncodingConfig function
    Write-Message "`nExample 8: Using New-VideoEncodingConfig function" -Type Processing
    $functionConfigs = @(
        (New-VideoEncodingConfig -Bitrate '5000k' -Preset 'slow'),
        (New-VideoEncodingConfig -CRF 23 -Preset 'slow'),
        (New-VideoEncodingConfig -QP 23 -Preset 'slow' -Mode 'CQP'),
        (New-VideoEncodingConfig -CRF 18 -Preset 'veryslow' -Profile 'high' -Level '4.1')
    )
    
    Write-Message "Function-created configurations:" -Type Info
    foreach ($config in $functionConfigs) {
        Write-Message "  $config" -Type Info
    }
    
    # Example 9: Encoding mode comparison
    Write-Message "`nExample 9: Encoding mode comparison" -Type Processing
    Write-Message "VBR (Variable Bitrate):" -Type Info
    Write-Message "  - Best for predictable file sizes" -Type Verbose
    Write-Message "  - Good for streaming and bandwidth-limited scenarios" -Type Verbose
    Write-Message "  - Example: $([VideoEncodingConfig]::new('5000k', 'slow'))" -Type Verbose
    
    Write-Message "CRF (Constant Rate Factor):" -Type Info
    Write-Message "  - Best for consistent quality" -Type Verbose
    Write-Message "  - Good for archiving and quality-focused scenarios" -Type Verbose
    Write-Message "  - Example: $([VideoEncodingConfig]::new(23, 'slow'))" -Type Verbose
    
    Write-Message "CQP (Constant Quantization Parameter):" -Type Info
    Write-Message "  - Direct quality control" -Type Verbose
    Write-Message "  - Good for specific quality requirements" -Type Verbose
    Write-Message "  - Example: $([VideoEncodingConfig]::new(23, 'slow', 'CQP'))" -Type Verbose
    
    # Example 10: Quality guidelines
    Write-Message "`nExample 10: Quality guidelines" -Type Processing
    Write-Message "CRF Quality Guidelines:" -Type Info
    Write-Message "  - 0: Lossless" -Type Verbose
    Write-Message "  - 18: Visually lossless" -Type Verbose
    Write-Message "  - 23: Default (good quality)" -Type Verbose
    Write-Message "  - 28: High quality" -Type Verbose
    Write-Message "  - 35: Medium quality" -Type Verbose
    Write-Message "  - 51: Worst quality" -Type Verbose
    
    Write-Message "Preset Guidelines:" -Type Info
    Write-Message "  - ultrafast: Fastest encoding, largest files" -Type Verbose
    Write-Message "  - superfast: Very fast encoding" -Type Verbose
    Write-Message "  - veryfast: Fast encoding" -Type Verbose
    Write-Message "  - faster: Faster encoding" -Type Verbose
    Write-Message "  - fast: Fast encoding" -Type Verbose
    Write-Message "  - medium: Balanced (default)" -Type Verbose
    Write-Message "  - slow: Better compression" -Type Verbose
    Write-Message "  - slower: Even better compression" -Type Verbose
    Write-Message "  - veryslow: Best compression, slowest encoding" -Type Verbose
    
    # Example 11: Integration with Convert-VideoFile
    Write-Message "`nExample 11: Integration with Convert-VideoFile" -Type Processing
    Write-Message "Example video encoding configurations for Convert-VideoFile:" -Type Info
    
    # Default configuration (what Convert-VideoFile uses when no VideoEncoding specified)
    $defaultConfig = [VideoEncodingConfig]::new('5000k', 'slow')
    Write-Message "Default configuration: $defaultConfig" -Type Info
    
    # High-quality configuration
    $highQualityConfig = [VideoEncodingConfig]::new(18, 'veryslow', 'high', '4.1')
    Write-Message "High-quality configuration: $highQualityConfig" -Type Info
    
    # Fast configuration
    $fastConfig = [VideoEncodingConfig]::new(28, 'ultrafast')
    Write-Message "Fast configuration: $fastConfig" -Type Info
    
    # Example 12: Profile and level examples
    Write-Message "`nExample 12: Profile and level examples" -Type Processing
    $profileExamples = @(
        (New-VideoEncodingConfig -CRF 23 -Preset 'slow' -Profile 'baseline' -Level '3.1'),
        (New-VideoEncodingConfig -CRF 23 -Preset 'slow' -Profile 'main' -Level '4.0'),
        (New-VideoEncodingConfig -CRF 23 -Preset 'slow' -Profile 'high' -Level '4.1'),
        (New-VideoEncodingConfig -CRF 23 -Preset 'slow' -Profile 'high422' -Level '4.2')
    )
    
    Write-Message "Profile and level examples:" -Type Info
    foreach ($config in $profileExamples) {
        Write-Message "  $config" -Type Info
    }
    
    Write-Message "`nAll VideoEncodingConfig examples completed successfully!" -Type Success
}
catch {
    Write-Message "VideoEncodingConfig examples failed: $($_.Exception.Message)" -Type Error
    throw
} 