function New-VideoEncodingSettings {
    <#
    .SYNOPSIS
        Creates a new VideoEncodingSettings object with specified encoding parameters.

    .DESCRIPTION
        New-VideoEncodingSettings creates a VideoEncodingSettings object that encapsulates
        video encoding parameters including codec, CRF (Constant Rate Factor), preset,
        codec profile, and tune settings. This object can be used with video encoding
        operations to ensure consistent parameter application.

    .PARAMETER Codec
        The video codec to use for encoding (e.g., 'h264', 'h265', 'vp9').

    .PARAMETER CRF
        The Constant Rate Factor value for quality control. Lower values indicate higher quality.
        Typical ranges: 18-28 for H.264, 20-30 for H.265.

    .PARAMETER Preset
        The encoding preset that balances speed vs. compression efficiency
        (e.g., 'ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium',
        'slow', 'slower', 'veryslow').

    .PARAMETER CodecProfile
        The codec profile to use (e.g., 'high', 'main', 'baseline' for H.264).

    .PARAMETER Tune
        The tuning option for the codec (e.g., 'film', 'animation', 'grain',
        'stillimage', 'fastdecode', 'zerolatency').

    .EXAMPLE
        $settings = New-VideoEncodingSettings -Codec 'h264' -CRF 23 -Preset 'medium' -CodecProfile 'high' -Tune 'film'
        Creates H.264 encoding settings optimized for film content.

    .EXAMPLE
        $settings = New-VideoEncodingSettings -Codec 'h265' -CRF 28 -Preset 'slow' -CodecProfile 'main' -Tune 'animation'
        Creates H.265 encoding settings optimized for animation content.

    .OUTPUTS
        VideoEncodingSettings
        Returns a VideoEncodingSettings object containing the specified encoding parameters.

    .LINK
        VideoEncodingSettings
    #>
    [CmdletBinding()]
    param(
<<<<<<< HEAD
        [Parameter(Mandatory)]
        [string] $Codec,
        [Parameter()]
        [int] $CRF = 21,
        [Parameter()]
        [string] $Preset = 'slow',
        [Parameter()]
        [string] $CodecProfile = 'high',
        [Parameter()]
        [string] $Tune = 'film'
    )
    process {
        return [VideoEncodingSettings]::new($Codec, $CRF, $Preset, $CodecProfile, $Tune)
=======
        [Parameter(Mandatory, ParameterSetName = 'CRF')]
        [Parameter(Mandatory, ParameterSetName = 'VBR')]
        [string] $Codec,
        [Parameter(Mandatory, ParameterSetName = 'VBR')]
        [double] $Bitrate,
        [Parameter(Mandatory, ParameterSetName = 'CRF')]
        [int] $CRF,
        [Parameter(ParameterSetName = 'CRF')]
        [Parameter(ParameterSetName = 'VBR')]
        [string] $Preset = 'slow',
        [Parameter(ParameterSetName = 'CRF')]
        [string] $CodecProfile = 'high',
        [Parameter(ParameterSetName = 'CRF')]
        [string] $Tune = 'film'
    )
    process {
        return [VideoEncodingSettings]::new($Codec, $Bitrate, $CRF, $Preset, $CodecProfile, $Tune)
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
    }
}
