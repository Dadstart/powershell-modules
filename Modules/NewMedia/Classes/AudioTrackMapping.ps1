<#
.SYNOPSIS
AudioTrackMapping - A class that represents an audio track mapping
.DESCRIPTION
AudioTrackMapping is a class that represents an audio track mapping.
.PARAMETER SourceIndex
#>
class AudioTrackMapping {
    [string]  $Title
    [int]     $SourceStream
    [int]     $SourceIndex
    [int]     $DestinationIndex
    [string]  $DestinationCodec
    [int]     $DestinationBitrate
    [int]     $DestinationChannels
    [bool]    $CopyOriginal

    AudioTrackMapping(
        [string] $title,
        [int]    $sourceStream,
        [int]    $sourceIndex,
        [int]    $destinationIndex,
        [string] $destinationCodec,
        [int]    $destinationBitrate,
        [int]    $destinationChannels,
        [bool]   $copyOriginal
    ) {
        $this.Title = $title
        $this.SourceStream = $sourceStream
        $this.SourceIndex = $sourceIndex
        $this.DestinationIndex = $destinationIndex
        $this.DestinationCodec = $destinationCodec
        $this.DestinationBitrate = $destinationBitrate
        $this.DestinationChannels = $destinationChannels
        $this.CopyOriginal = $copyOriginal
    }

    [string] ToString() {
        return "Audio stream $($this.SourceIndex) → $($this.DestinationCodec)@$($this.DestinationBitrate)k (→ index $($this.DestinationIndex))" + $(if ($this.CopyOriginal) {
                ' [Copy]'
            }
            else {
                ''
            })
    }

    [string[]] ToFfmpegArgs() {
        $ffmpegArgs = New-Object System.Collections.Generic.List[string]
        $ffmpegArgs.Add('-map')
        $ffmpegArgs.Add("$($this.SourceStream):a:$($this.SourceIndex)")
        $ffmpegArgs.Add("-c:a:$($this.DestinationIndex)")
        if ($this.CopyOriginal) {
            $ffmpegArgs.Add('copy')
            if ($this.Title) {
                $ffmpegArgs.Add("-metadata:s:a:$($this.DestinationIndex)")
                $ffmpegArgs.Add("title=`"$($this.Title)`"")
            }
        }
        else {
            $ffmpegArgs.Add($this.DestinationCodec)
            $ffmpegArgs.Add("-b:a:$($this.DestinationIndex)")
            if (-not $this.DestinationBitrate -and -not $this.DestinationChannels) {
                Write-Message 'No channels or bitrate provided for this audio track' -Type Warning
            }
            $bps = $this.DestinationBitrate
            if (-not $bps) {
                $bps = switch ($this.DestinationChannels) {
                    1 {
                        80
                    }
                    2 {
                        160
                    }
                    6 {
                        384
                    }
                    8 {
                        512
                    }
                    default {
                        Write-Message "No default bitrate found for $($this.DestinationChannels) channels" -Type Error
                        throw "No default bitrate found for $($this.DestinationChannels) channels"
                    }
                }
            }
            $ffmpegArgs.Add("$($bps)k")
            if ($this.DestinationChannels) {
                $ffmpegArgs.Add("-ac:a:$($this.DestinationIndex)")
                $ffmpegArgs.Add($this.DestinationChannels)
            }
            if ($this.Title) {
                $ffmpegArgs.Add("-metadata:s:a:$($this.DestinationIndex)")
                $ffmpegArgs.Add("title=`"$($this.Title)`"")
            }
        }
        return $ffmpegArgs.ToArray()
    }
}
