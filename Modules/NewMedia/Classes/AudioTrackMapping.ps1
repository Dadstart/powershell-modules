<#
.SYNOPSIS
AudioTrackMapping - A class that represents an audio track mapping
.DESCRIPTION
AudioTrackMapping is a class that represents an audio track mapping.
.PARAMETER SourceIndex
#>
class AudioTrackMapping {
    [int]     $SourceIndex
    [string]  $SourceLanguage
    [string]  $SourceCodec
    [int]     $DestinationIndex
    [string]  $DestinationCodec
    [int]     $Bitrate
    [bool]    $CopyOriginal
    AudioTrackMapping(
        [int]    $sourceIndex,
        [string] $sourceLanguage,
        [string] $sourceCodec,
        [int]    $destinationIndex,
        [string] $destinationCodec,
        [int]    $bitrate,
        [bool]   $copyOriginal
    ) {
        $this.SourceIndex = $sourceIndex
        $this.SourceLanguage = $sourceLanguage
        $this.SourceCodec = $sourceCodec
        $this.DestinationIndex = $destinationIndex
        $this.DestinationCodec = $destinationCodec
        $this.Bitrate = $bitrate
        $this.CopyOriginal = $copyOriginal
    }
    [string] ToString() {
        return "Audio stream $($this.SourceIndex) [$($this.SourceLanguage)] → $($this.DestinationCodec)@$($this.Bitrate)k (→ index $($this.DestinationIndex))" + $(if ($this.CopyOriginal) {
                ' [Copy]'
            }
            else {
                ''
            })
    }
    [string[]] ToFfmpegArgs() {
        $ffmpegArgs = @('-map', "0:a:$($this.SourceIndex)")
        if ($this.CopyOriginal) {
            $ffmpegArgs += "-c:a:$($this.DestinationIndex)", 'copy'
        }
        else {
            $ffmpegArgs += "-c:a:$($this.DestinationIndex)", $this.DestinationCodec
            $ffmpegArgs += "-b:a:$($this.DestinationIndex)", "$($this.Bitrate)k"
        }
        return $ffmpegArgs
    }
}
