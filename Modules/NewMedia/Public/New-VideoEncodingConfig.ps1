function New-VideoEncodingConfig {
    [CmdletBinding(DefaultParameterSetName = 'VBR')]
    <#
    .SYNOPSIS
        Creates a video encoding configuration for video conversion.
    .DESCRIPTION
        New-VideoEncodingConfig creates a VideoEncodingConfig object that defines how video
        should be encoded during video conversion. It supports three encoding modes:
        VBR (Variable Bitrate), CRF (Constant Rate Factor), and CQP (Constant Quantization Parameter).
        
        Encoding Modes:
        - VBR: Fixed bitrate encoding for predictable file sizes
        - CRF: Quality-based encoding for consistent quality
        - CQP: Direct quality control for specific quality requirements
    .PARAMETER Bitrate
        The target bitrate for VBR encoding (e.g., '5000k', '2500k').
    .PARAMETER CRF
        The CRF value for quality-based encoding (0-51, lower is better).
    .PARAMETER QP
        The quantization parameter for CQP encoding (0-51, lower is better).
    .PARAMETER Preset
        The libx264 preset to use. Default is 'slow'.
    .PARAMETER Profile
        The H.264 profile to use (optional).
    .PARAMETER Level
        The H.264 level to use (optional).
    .PARAMETER Mode
        The encoding mode to use ('VBR', 'CRF', 'CQP').
    .EXAMPLE
        $config = New-VideoEncodingConfig -Bitrate '5000k' -Preset 'slow'
        Creates a VBR configuration with 5000k bitrate and slow preset.
    .EXAMPLE
        $config = New-VideoEncodingConfig -CRF 23 -Preset 'slow'
        Creates a CRF configuration with CRF 23 and slow preset.
    .EXAMPLE
        $config = New-VideoEncodingConfig -QP 23 -Preset 'slow' -Mode 'CQP'
        Creates a CQP configuration with QP 23 and slow preset.
    .EXAMPLE
        $config = New-VideoEncodingConfig -CRF 18 -Preset 'veryslow' -Profile 'high' -Level '4.1'
        Creates a high-quality CRF configuration with specific profile and level.
    .OUTPUTS
        [VideoEncodingConfig] A video encoding configuration object.
    .NOTES
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
    [OutputType([object])]
    param (
        [Parameter(ParameterSetName = 'VBR', Mandatory = $true)]
        [string]$Bitrate,

        [Parameter(ParameterSetName = 'CRF', Mandatory = $true)]
        [ValidateRange(0, 51)]
        [int]$CRF,

        [Parameter(ParameterSetName = 'CQP', Mandatory = $true)]
        [ValidateRange(0, 51)]
        [int]$QP,

        [Parameter()]
        [ValidateSet('ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow')]
        [string]$Preset = 'slow',

        [Parameter()]
        [ValidateSet('baseline', 'main', 'high', 'high422', 'high444')]
        [string]$Profile,

        [Parameter()]
        [ValidateSet('3.0', '3.1', '4.0', '4.1', '4.2', '5.0', '5.1', '5.2')]
        [string]$Level,

        [Parameter(ParameterSetName = 'CQP', Mandatory = $true)]
        [ValidateSet('CQP')]
        [string]$Mode
    )

    switch ($PSCmdlet.ParameterSetName) {
        'VBR' {
            return [VideoEncodingConfig]::new($Bitrate, $Preset, $Profile, $Level)
        }
        'CRF' {
            return [VideoEncodingConfig]::new($CRF, $Preset, $Profile, $Level)
        }
        'CQP' {
            return [VideoEncodingConfig]::new($QP, $Preset, $Mode, $Profile, $Level)
        }
    }
} 