<#
.SYNOPSIS
VideoEncodingSettings - A class that represents video encoding settings
.DESCRIPTION
VideoEncodingSettings is a class that represents video encoding settings.
.PARAMETER Codec
#>
class VideoEncodingSettings {
    [string] $Codec = 'libx264'
    [int]    $CRF = 22
    [string] $Preset = 'medium'
    [string] $Resolution # e.g. '1920x1080'
    VideoEncodingSettings(
        [string] $codec,
        [int]    $crf,
        [string] $preset,
        [string] $resolution
    ) {
        $this.Codec = $codec
        $this.CRF = $crf
        $this.Preset = $preset
        $this.Resolution = $resolution
    }
    [string] ToString() {
        return "$($this.Codec), CRF=$($this.CRF), Preset=$($this.Preset)" + $(if ($this.Resolution) {
                ", Scale=$($this.Resolution)" 
            }
            else {
                '' 
            })
    }
    [string[]] ToFfmpegArgs() {
        $ffmpegArgs = @('-c:v', $this.Codec, '-crf', "$($this.CRF)", '-preset', $this.Preset)
        if ($this.Resolution) {
            $ffmpegArgs += @('-vf', "scale=$($this.Resolution)")
        }
        return $ffmpegArgs
    }
}
