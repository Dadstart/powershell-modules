<#
.SYNOPSIS
    VideoEncodingConfig - Configuration class for video encoding during video conversion.

.DESCRIPTION
    VideoEncodingConfig represents video encoding configuration for video conversion operations.
    This class defines how video should be encoded, supporting different modes like VBR (Variable Bitrate),
    CRF (Constant Rate Factor), and CQP (Constant Quantization Parameter).

    The class supports three encoding modes:
    - VBR (Variable Bitrate): Fixed bitrate encoding for predictable file sizes
    - CRF (Constant Rate Factor): Quality-based encoding for consistent quality
    - CQP (Constant Quantization Parameter): Direct quality control

    Properties:
    - EncodingMode: The encoding mode to use ('VBR', 'CRF', 'CQP')
    - Bitrate: The target bitrate for VBR mode (e.g., '5000k')
    - CRF: The CRF value for quality-based encoding (0-51, lower is better)
    - QP: The quantization parameter for CQP mode (0-51, lower is better)
    - Preset: The libx264 preset to use
    - Profile: The H.264 profile to use (optional)
    - Level: The H.264 level to use (optional)

    Constructors:
    - VideoEncodingConfig(bitrate, preset): For VBR mode
    - VideoEncodingConfig(crf, preset): For CRF mode
    - VideoEncodingConfig(qp, preset): For CQP mode

    Methods:
    - ToString(): Returns a human-readable description of the configuration
    - GetFFmpegArgs(): Returns FFmpeg arguments for the encoding configuration

.EXAMPLE
    # Create a VBR configuration
    $vbrConfig = [VideoEncodingConfig]::new('5000k', 'slow')
    Write-Host $vbrConfig.ToString()
    # Output: VBR encoding with bitrate 5000k, preset slow

.EXAMPLE
    # Create a CRF configuration
    $crfConfig = [VideoEncodingConfig]::new(23, 'slow')
    Write-Host $crfConfig.ToString()
    # Output: CRF encoding with CRF 23, preset slow

.EXAMPLE
    # Using with Convert-VideoFile
    $videoConfig = [VideoEncodingConfig]::new(23, 'slow')
    Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4" -VideoEncoding $videoConfig

.NOTES
    This class is designed to work with the Convert-VideoFile function and provides a flexible
    way to configure video encoding parameters.

    Encoding Modes:
    - VBR: Best for predictable file sizes, good for streaming
    - CRF: Best for consistent quality, good for archiving
    - CQP: Direct quality control, good for specific quality requirements

    CRF Values:
    - 0: Lossless
    - 18: Visually lossless
    - 23: Default (good quality)
    - 28: High quality
    - 35: Medium quality
    - 51: Worst quality

    QP Values:
    - 0: Lossless
    - 18: Visually lossless
    - 23: Default
    - 28: High quality
    - 35: Medium quality
    - 51: Worst quality

    Presets (speed vs compression):
    - ultrafast: Fastest encoding, largest files
    - superfast: Very fast encoding
    - veryfast: Fast encoding
    - faster: Faster encoding
    - fast: Fast encoding
    - medium: Balanced (default)
    - slow: Better compression
    - slower: Even better compression
    - veryslow: Best compression, slowest encoding
#>
class VideoEncodingConfig {
    <#
    .SYNOPSIS
        The encoding mode to use.
    .DESCRIPTION
        Specifies the video encoding mode:
        - 'VBR': Variable Bitrate - fixed bitrate for predictable file sizes
        - 'CRF': Constant Rate Factor - quality-based encoding
        - 'CQP': Constant Quantization Parameter - direct quality control
    #>
    [string]$EncodingMode

    <#
    .SYNOPSIS
        The target bitrate for VBR mode.
    .DESCRIPTION
        Specifies the target bitrate for VBR encoding. Common values:
        - '1000k': Low quality, small file size
        - '2500k': Medium quality, reasonable size
        - '5000k': High quality, larger file size
        - '8000k': Very high quality, large file size
    #>
    [string]$Bitrate

    <#
    .SYNOPSIS
        The CRF value for quality-based encoding.
    .DESCRIPTION
        Specifies the Constant Rate Factor for quality-based encoding (0-51):
        - 0: Lossless
        - 18: Visually lossless
        - 23: Default (good quality)
        - 28: High quality
        - 35: Medium quality
        - 51: Worst quality
    #>
    [int]$CRF

    <#
    .SYNOPSIS
        The quantization parameter for CQP mode.
    .DESCRIPTION
        Specifies the quantization parameter for CQP encoding (0-51):
        - 0: Lossless
        - 18: Visually lossless
        - 23: Default
        - 28: High quality
        - 35: Medium quality
        - 51: Worst quality
    #>
    [int]$QP

    <#
    .SYNOPSIS
        The libx264 preset to use.
    .DESCRIPTION
        Specifies the encoding speed vs compression trade-off:
        - ultrafast: Fastest encoding, largest files
        - superfast: Very fast encoding
        - veryfast: Fast encoding
        - faster: Faster encoding
        - fast: Fast encoding
        - medium: Balanced (default)
        - slow: Better compression
        - slower: Even better compression
        - veryslow: Best compression, slowest encoding
    #>
    [string]$Preset

    <#
    .SYNOPSIS
        The H.264 profile to use (optional).
    .DESCRIPTION
        Specifies the H.264 profile for compatibility:
        - 'baseline': Maximum compatibility
        - 'main': Good compatibility
        - 'high': Better quality, less compatibility
        - 'high422': High quality with 4:2:2 chroma
        - 'high444': High quality with 4:4:4 chroma
    #>
    [string]$Profile

    <#
    .SYNOPSIS
        The H.264 level to use (optional).
    .DESCRIPTION
        Specifies the H.264 level for compatibility:
        - '3.0': Standard definition
        - '3.1': Standard definition
        - '4.0': High definition
        - '4.1': High definition
        - '4.2': High definition
        - '5.0': Ultra high definition
        - '5.1': Ultra high definition
        - '5.2': Ultra high definition
    #>
    [string]$Level

    <#
    .SYNOPSIS
        Constructor for creating a VBR video encoding configuration.
    .DESCRIPTION
        Creates a new VideoEncodingConfig for VBR (Variable Bitrate) encoding.
        This constructor is used when you want predictable file sizes.
    .PARAMETER bitrate
        The target bitrate for encoding (e.g., '5000k').
    .PARAMETER preset
        The libx264 preset to use (e.g., 'slow').
    .PARAMETER profile
        The H.264 profile to use (optional).
    .PARAMETER level
        The H.264 level to use (optional).
    .EXAMPLE
        $config = [VideoEncodingConfig]::new('5000k', 'slow')
        # Creates VBR configuration with 5000k bitrate and slow preset
    #>
    VideoEncodingConfig([string]$bitrate, [string]$preset, [string]$profile = $null, [string]$level = $null) {
        $this.EncodingMode = 'VBR'
        $this.Bitrate = $bitrate
        $this.CRF = $null
        $this.QP = $null
        $this.Preset = $preset
        $this.Profile = $profile
        $this.Level = $level
    }

    <#
    .SYNOPSIS
        Constructor for creating a CRF video encoding configuration.
    .DESCRIPTION
        Creates a new VideoEncodingConfig for CRF (Constant Rate Factor) encoding.
        This constructor is used when you want consistent quality.
    .PARAMETER crf
        The CRF value for quality-based encoding (0-51).
    .PARAMETER preset
        The libx264 preset to use (e.g., 'slow').
    .PARAMETER profile
        The H.264 profile to use (optional).
    .PARAMETER level
        The H.264 level to use (optional).
    .EXAMPLE
        $config = [VideoEncodingConfig]::new(23, 'slow')
        # Creates CRF configuration with CRF 23 and slow preset
    #>
    VideoEncodingConfig([int]$crf, [string]$preset, [string]$profile = $null, [string]$level = $null) {
        $this.EncodingMode = 'CRF'
        $this.Bitrate = $null
        $this.CRF = $crf
        $this.QP = $null
        $this.Preset = $preset
        $this.Profile = $profile
        $this.Level = $level
    }

    <#
    .SYNOPSIS
        Constructor for creating a CQP video encoding configuration.
    .DESCRIPTION
        Creates a new VideoEncodingConfig for CQP (Constant Quantization Parameter) encoding.
        This constructor is used when you want direct quality control.
    .PARAMETER qp
        The quantization parameter for encoding (0-51).
    .PARAMETER preset
        The libx264 preset to use (e.g., 'slow').
    .PARAMETER profile
        The H.264 profile to use (optional).
    .PARAMETER level
        The H.264 level to use (optional).
    .EXAMPLE
        $config = [VideoEncodingConfig]::new(23, 'slow', 'CQP')
        # Creates CQP configuration with QP 23 and slow preset
    #>
    VideoEncodingConfig([int]$qp, [string]$preset, [string]$mode, [string]$profile = $null, [string]$level = $null) {
        if ($mode -eq 'CQP') {
            $this.EncodingMode = 'CQP'
            $this.Bitrate = $null
            $this.CRF = $null
            $this.QP = $qp
            $this.Preset = $preset
            $this.Profile = $profile
            $this.Level = $level
        } else {
            throw "Invalid mode. Use 'CQP' for Constant Quantization Parameter encoding."
        }
    }

    <#
    .SYNOPSIS
        Returns a human-readable description of the video encoding configuration.
    .DESCRIPTION
        Converts the VideoEncodingConfig to a string representation that clearly shows
        the encoding mode and parameters.
    .RETURNVALUE
        A string describing the video encoding configuration.
    .EXAMPLE
        $config = [VideoEncodingConfig]::new('5000k', 'slow')
        Write-Host $config.ToString()
        # Output: VBR encoding with bitrate 5000k, preset slow
    .EXAMPLE
        $config = [VideoEncodingConfig]::new(23, 'slow')
        Write-Host $config.ToString()
        # Output: CRF encoding with CRF 23, preset slow
    #>
    [string]ToString() {
        $description = "$($this.EncodingMode) encoding"
        
        switch ($this.EncodingMode) {
            'VBR' { $description += " with bitrate $($this.Bitrate)" }
            'CRF' { $description += " with CRF $($this.CRF)" }
            'CQP' { $description += " with QP $($this.QP)" }
        }
        
        $description += ", preset $($this.Preset)"
        
        if ($this.Profile) {
            $description += ", profile $($this.Profile)"
        }
        
        if ($this.Level) {
            $description += ", level $($this.Level)"
        }
        
        return $description
    }

    <#
    .SYNOPSIS
        Returns FFmpeg arguments for the video encoding configuration.
    .DESCRIPTION
        Generates the appropriate FFmpeg arguments based on the encoding mode
        and parameters specified in the configuration.
    .RETURNVALUE
        An array of FFmpeg arguments for video encoding.
    .EXAMPLE
        $config = [VideoEncodingConfig]::new('5000k', 'slow')
        $args = $config.GetFFmpegArgs()
        # Returns: @('-c:v', 'libx264', '-preset', 'slow', '-b:v', '5000k')
    #>
    [object[]]GetFFmpegArgs() {
        $args = @('-c:v', 'libx264', '-preset', $this.Preset)
        
        switch ($this.EncodingMode) {
            'VBR' { 
                $args += '-b:v', $this.Bitrate
            }
            'CRF' { 
                $args += '-crf', $this.CRF.ToString()
            }
            'CQP' { 
                $args += '-qp', $this.QP.ToString()
            }
        }
        
        if ($this.Profile) {
            $args += '-profile:v', $this.Profile
        }
        
        if ($this.Level) {
            $args += '-level', $this.Level
        }
        
        return $args
    }
} 