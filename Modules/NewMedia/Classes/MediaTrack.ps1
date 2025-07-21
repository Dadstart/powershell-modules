class MediaTrack {
    [int]      $Index
    [string]   $Type
    [string]   $Codec
    [string]   $Language
    [int]      $Bitrate
    [string]   $Title
    [TimeSpan] $Duration
    [psobject] $Raw

    MediaTrack([psobject]$stream) {
        $this.Index    = $stream.index
        $this.Type     = $stream.codec_type
        $this.Codec    = $stream.codec_name
        $this.Language = $stream.tags.language
        $this.Bitrate  = [int]$stream.bit_rate
        $this.Title    = $stream.tags.title
        $this.Duration = [TimeSpan]::FromSeconds([double]$stream.duration)
        $this.Raw      = $stream
    }

    [string] ToString() {
        return "$($this.Type) Stream $($this.Index): $($this.Codec) [$($this.Language)]"
    }
}
