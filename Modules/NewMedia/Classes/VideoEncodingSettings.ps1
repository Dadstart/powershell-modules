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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
    [double] $Bitrate
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
    [double] $Bitrate
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
    [double] $Bitrate
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
    [int]    $CRF
    [string] $Preset
    [string] $CodecProfile
    [string] $Tune

    VideoEncodingSettings(
        [string] $codec,
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
        [int]    $crf = 21,
        [string] $preset = 'slow',
        [string] $codecProfile = 'high',
        [string] $tune = 'film'
    ) {
        $this.Codec = $codec
=======
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
        [double] $bitrate,
        [int]    $crf,
        [string] $preset,
        [string] $codecProfile,
        [string] $tune
    ) {
        $this.Codec = $codec
        $this.Bitrate = $bitrate
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
        $this.Preset = $preset
        $this.CRF = $crf
        $this.CodecProfile = $codecProfile
        $this.Tune = $tune
    }
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)

    [string] ToString() {
        if ($this.Bitrate) {
            return "$($this.Codec), Bitrate=$($this.Bitrate)k, Preset=$($this.Preset)"
        }
        else {

            return "$($this.Codec), CRF=$($this.CRF), Preset=$($this.Preset)"
        }
    }

    [string[]] ToFfmpegArgs([int] $pass) {
        if (($pass -lt 0) -or ($pass -gt 2)) {
            throw 'Phase must be 0, 1 or 2'
        }

        # Construct ffmpeg command
        $ffmpegArgs = New-Object System.Collections.Generic.List[string]
        if ($this.CRF -or ($pass -eq 2)) {
            $ffmpegArgs.Add('-map')
            $ffmpegArgs.Add('0:v:0')
        }

        $libCodec = $this.Codec -eq 'x264' ? 'libx264' : $this.Codec
        $ffmpegArgs.Add('-c:v')
        $ffmpegArgs.Add($libCodec)
        $ffmpegArgs.Add('-preset')
        $ffmpegArgs.Add($this.Preset)
        if ($this.Bitrate) {
            $ffmpegArgs.Add('-b:v')
            $ffmpegArgs.Add("$($this.Bitrate)k")
        }
        else {
            $ffmpegArgs.Add('-crf')
            $ffmpegArgs.Add($this.CRF)
            $ffmpegArgs.Add('-pix_fmt')
            $ffmpegArgs.Add('yuv420p')
        }

        if ($this.CRF -or ($pass -eq 2)) {
            $ffmpegArgs.Add('-map_metadata')
            $ffmpegArgs.Add('0')
            $ffmpegArgs.Add('-map_chapters')
            $ffmpegArgs.Add('0')
            $ffmpegArgs.Add('-movflags')
            $ffmpegArgs.Add('+faststart')
        }

        return $ffmpegArgs.ToArray()
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
=======
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
    }
}
