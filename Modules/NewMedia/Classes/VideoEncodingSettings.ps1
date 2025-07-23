<#
.SYNOPSIS
VideoEncodingSettings - A class that represents video encoding settings

.DESCRIPTION
VideoEncodingSettings is a class that represents video encoding settings.

.PARAMETER Codec
The codec to use. Supported values are 'x264'.

.PARAMETER CRF
The constant rate factor (CRF) value to use. Default is 21. Balances quality and file size (lower = better quality).

.PARAMETER Preset
The preset to use. Default is 'slow'.

.PARAMETER CodecProfile
The codec profile to use. Default is 'high'.

.PARAMETER Tune
The tune to use.

#>
class VideoEncodingSettings {
    [string] $Codec
    [int]    $CRF
    [string] $Preset
    [string] $CodecProfile
    [string] $Tune

    VideoEncodingSettings(
        [string] $codec,
        [int]    $crf = 21,
        [string] $preset = 'slow',
        [string] $codecProfile = 'high',
        [string] $tune = 'film'
    ) {
        $this.Codec = $codec
        $this.Preset = $preset
        $this.CRF = $crf
        $this.CodecProfile = $codecProfile
        $this.Tune = $tune
    }
    [string] ToString() {
        return "$($this.Codec), CRF=$($this.CRF), Preset=$($this.Preset)"
    }

    [string[]] ToFfmpegArgs() {
        # Build x264 parameters
        $x264Params = @(
            "psy_rd='1.00:0.15'", # Strength of psy-RD and psy-Trellis
            'aq-mode=1', # Adaptive quantization mode
            'aq-strength=1.00', # Adaptive strength
            'vbv_maxrate=25000', # Max bitrate allowed by video buffering verifier (VBV)
            'vbv_bufsize=31250', # Buffer size for VBV - affects bitrate smoothing
            'keyint=240',
            'keyint_min=24',
            'scenecut=40',
            'rc_lookahead=50',
            'qcomp=0.60', # Quanitizer curve compression - balances constant quality vs bitrate spikes
            'qpmin=0', # Minum quanitizer value - lower bound for compression
            'qpmax=69', # Maximum quanitizer value - upper bound for compression
            'qpstep=4', # Max step between quanitizers - controls quality fluctiation
            "crf=$($this.CRF).0", # Constant rate factor - controls quality and bitrate
            'rc=crf' # Rate control mode - CRF for variable bitrate
            # 'analyse=0x3:0x113', # Partition analysis flags - controls intra/inter block decisions
            'chroma_qp_offset=-3' # Chroma quantization offset
        ) -join ':'

        # Construct ffmpeg command
        $libCodec = $this.Codec -eq 'x264' ? 'libx264' : $this.Codec
        $ffmpegArgs = @(
            '-map', '0:v:0',
            '-c:v', $libCodec,
            '-preset', $this.Preset,
            # temporarily skip -tune in case it is overriding other x264 settings
            '-tune', $this.Tune,
            '-crf', $this.CRF,
            '-profile:v', $this.CodecProfile,
            '-level:v', '4.0',
            '-x264-params', "`"$x264Params`"",
            # No Audio mapping here, leaving in for reference
            # '-map 0:a:0 -c:a:0 aac -b:a:0 384k -ac 6',
            # '-map 0:a:1 -c:a:1 copy',
            '-map_metadata', '0',
            '-map_chapters', '0',
            '-movflags', '+faststart'
        )

        return $ffmpegArgs
    }
}
