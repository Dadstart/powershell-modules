function Get-HandbrakeOptions {
    <#
    .SYNOPSIS
        Generates HandBrake command line options based on audio streams and encoding preferences.
    .DESCRIPTION
        Creates a standardized array of HandBrake options based on the provided audio streams and
        encoding preferences. This centralizes the common HandBrake options configuration used
        across multiple functions. The function processes multiple audio streams and generates
        appropriate encoder, mixdown, and bitrate settings for each stream.
    .PARAMETER AudioStreams
        Array of audio stream objects containing Index and Title properties.
        Each stream object should have an Index (for stream selection) and Title (for determining mixdown and bitrate).
    .PARAMETER Language
        The language code for audio streams. Default is 'eng'.
    .PARAMETER Encoder
        The video encoder to use. Valid values are:
        - svt_av1, svt_av1_10bit
        - x264, x264_10bit
        - nvenc_h264
        - x265, x265_10bit, x265_12bit
        - nvenc_h265, nvenc_h265_10bit
        - mpeg4, mpeg2
        - VP8, VP9, VP9_10bit
        - theora
    .PARAMETER Quality
        The quality setting for the encoder. Valid ranges vary by encoder:
        - x264/x264_10bit: 0-51 (lower is better quality, 18-28 recommended)
        - x265/x265_10bit/x265_12bit: 0-51 (lower is better quality, 18-28 recommended)
        - svt_av1/svt_av1_10bit: 0-63 (lower is better quality, 20-30 recommended)
        - VP9/VP9_10bit: 0-63 (lower is better quality, 20-30 recommended)
        - nvenc_h264/nvenc_h265/nvenc_h265_10bit: 0-51 (lower is better quality)
        - mpeg4: 0-31 (lower is better quality)
        - mpeg2: 0-31 (lower is better quality)
        - VP8: 0-63 (lower is better quality)
        - theora: 0-63 (lower is better quality)
    .PARAMETER EncoderPreset
        The encoder preset to use. Valid values vary by encoder:
        - x264/x264_10bit: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
        - x265/x265_10bit/x265_12bit: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
        - svt_av1/svt_av1_10bit: 0-13 (0=fastest, 13=slowest, 8=medium recommended)
        - VP9/VP9_10bit: 0-16 (0=fastest, 16=slowest, 8=medium recommended)
        - nvenc_h264/nvenc_h265/nvenc_h265_10bit: fast, medium, slow, hq, ll, llhq, lossless
        - mpeg4/mpeg2: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
        - VP8: 0-16 (0=fastest, 16=slowest, 8=medium recommended)
        - theora: 0-10 (0=fastest, 10=slowest, 5=medium recommended)
    .PARAMETER EncoderTune
        The encoder tune setting. Valid values vary by encoder:
        - x264/x264_10bit: film, animation, grain, stillimage, fastdecode, zerolatency, psnr, ssim
        - x265/x265_10bit/x265_12bit: fastdecode, zerolatency, psnr, ssim
        - svt_av1/svt_av1_10bit: (not applicable)
        - VP9/VP9_10bit: (not applicable)
        - nvenc_h264/nvenc_h265/nvenc_h265_10bit: fastdecode, ll, llhq, lossless
        - mpeg4/mpeg2: (not applicable)
        - VP8: (not applicable)
        - theora: (not applicable)
        Default is $null.
    .PARAMETER EncOpts
        Additional encoder options as a string. Default is $null.
    .PARAMETER Chapters
        Chapter range specification in format "1-3" for chapters 1 to 3, or "3" for chapter 3 only.
        If not specified, all chapters will be included.
    .EXAMPLE
        $streams = @(
            @{ Index = 1; Title = "Surround 5.1" },
            @{ Index = 2; Title = "Stereo Commentary" }
        )
        $options = Get-HandbrakeOptions -AudioStreams $streams -Encoder "x264" -Quality "21"
    .EXAMPLE
        $streams = @(
            @{ Index = 1; Title = "Stereo" }
        )
        $options = Get-HandbrakeOptions -AudioStreams $streams -Encoder "x264" -Quality "21" -EncoderPreset "slow" -EncoderTune "film"
    .OUTPUTS
        Array of HandBrake command line options including:
        - Video encoder and quality settings
        - Audio stream selections
        - Audio encoder settings (av_aac for all streams)
        - Mixdown settings based on stream titles
        - Bitrate settings based on stream titles
        - Optional encoder preset, tune, and additional options
    .NOTES
        This function relies on Convert-TypeToMixdown and Convert-TypeToBitrate functions
        to determine appropriate mixdown and bitrate settings based on the audio stream titles.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [object[]]$AudioStreams = @(),
        [Parameter()]
        [string]$Language = 'eng',
        [Parameter(Mandatory)]
        [ValidateSet('svt_av1', 'svt_av1_10bit', 'x264', 'x264_10bit', 'nvenc_h264', 'x265', 'x265_10bit', 'x265_12bit', 'nvenc_h265', 'nvenc_h265_10bit', 'mpeg4', 'mpeg2', 'VP8', 'VP9', 'VP9_10bit', 'theora')]
        [string]$Encoder,
        [Parameter(Mandatory)]
        [int]$Quality,
        [Parameter()]
        [string]$EncoderPreset,
        [Parameter()]
        [string]$EncoderTune,
        [Parameter()]
        [string]$EncoderOptions,
        [Parameter()]
        [string]$Chapters
    )
    $options = @(
        '--encoder', $Encoder,
        '--quality', $Quality,
        '--vfr'
    )
    # handle audio streams (0 or more)
    $audioStreamsCount = $AudioStreams ? $AudioStreams.Count : 0
    Write-Message "Audio streams provided: $audioStreamsCount" -Type Debug
    if ($audioStreamsCount -gt 0) {
        $audioOptions = @()
        $aencoderOptions = @()
        $mixdownOptions = @()
        $abOptions = @()
        foreach ($stream in $AudioStreams) {
            $audioOptions += $stream.Index
            $aencoderOptions += 'av_aac'
            $mixdownOptions += (Convert-TypeToMixdown -Type $stream.Title)
            $abOptions += (Convert-TypeToBitrate -Type $stream.Title)
        }
        $options += @('--audio', ($audioOptions -join ','))
        $options += @('--aencoder', ($aencoderOptions -join ','))
        $options += @('--mixdown', ($mixdownOptions -join ','))
        $options += @('--ab', ($abOptions -join ','))
    }
    if ($EncoderPreset) {
        $options += @('--encoder-preset', $EncoderPreset)
    }
    if ($EncoderTune) {
        $options += @('--encoder-tune', $EncoderTune)
    }
    if ($EncoderOptions) {
        $options += @('--encopts', $EncoderOptions)
    }
    if ($Chapters) {
        $options += @('--chapters', $Chapters)
    }
    return $options
}
