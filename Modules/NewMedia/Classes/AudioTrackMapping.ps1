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

    [hashtable] ToFfmpegArgs() {
        $ffmpegArgs = @{}
        $ffmpegArgs['-map'] = "$($this.SourceStream):a:$($this.SourceIndex)"
        $ffmpegArgs["-c:a:$($this.DestinationIndex)"] = if ($this.CopyOriginal) { 'copy' } else { $this.DestinationCodec }
        
        if ($this.CopyOriginal) {
            if ($this.Title) {
                $ffmpegArgs["-metadata:s:a:$($this.DestinationIndex)"] = "title=`"$($this.Title)`""
            }
        }
        else {
            if (-not $this.DestinationBitrate -and -not $this.DestinationChannels) {
                Write-Message 'No channels or bitrate provided for this audio track' -Type Warning
            }
            $bps = $this.DestinationBitrate
            if (-not $bps) {
                $bps = switch ($this.DestinationChannels) {
                    1 { 80 }
                    2 { 160 }
                    6 { 384 }
                    8 { 512 }
                    default {
                        Write-Message "No default bitrate found for $($this.DestinationChannels) channels" -Type Error
                        throw "No default bitrate found for $($this.DestinationChannels) channels"
                    }
                }
            }
            $ffmpegArgs["-b:a:$($this.DestinationIndex)"] = "$($bps)k"
            if ($this.DestinationChannels) {
                $ffmpegArgs["-ac:a:$($this.DestinationIndex)"] = $this.DestinationChannels
            }
            if ($this.Title) {
                $ffmpegArgs["-metadata:s:a:$($this.DestinationIndex)"] = "title=`"$($this.Title)`""
            }
        }
        return $ffmpegArgs
    }
}
