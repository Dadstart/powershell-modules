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
    [double] $Bitrate
    [int]    $CRF
    [string] $Preset
    [string] $CodecProfile
    [string] $Tune
    [string[]] $AdditionalArgs

    VideoEncodingSettings(
        [string] $codec,
        [double] $bitrate,
        [int]    $crf,
        [string] $preset,
        [string] $codecProfile,
        [string] $tune,
        [string[]] $additionalArgs
    ) {
        $this.Codec = $codec
        $this.Bitrate = $bitrate
        $this.Preset = $preset
        $this.CRF = $crf
        $this.CodecProfile = $codecProfile
        $this.Tune = $tune
        $this.AdditionalArgs = $additionalArgs
    }


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

        $libCodec = switch ($this.Codec) {
            'x264' { 'libx264' }
            'x265' { 'libx265' }
            default { $this.Codec }
        }

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

        if ($this.AdditionalArgs) {
            $ffmpegArgs.AddRange($this.AdditionalArgs)
        }

        return $ffmpegArgs.ToArray()
    }
}
