class MediaFormat {
    [string] $Path
    [string] $Title
    [int] $StreamCount
    [string] $Format
    [string] $FormatLongName
    [int] $StartTime
    [int] $Duration
    [double] $Size
    [int] $BitRate
    [int] $ProbeScore
    [hashtable] $Tags
    [psobject] $Raw

    MediaFormat([psobject] $FormatObject) {
        $this.Path = $FormatObject.filename
        $this.Title = $FormatObject.tags.title
        $this.StreamCount = $FormatObject.nb_streams
        $this.Format = $FormatObject.format_name
        $this.FormatLongName = $FormatObject.format_long_name
        $this.StartTime = $FormatObject.start_time
        $this.Duration = $FormatObject.duration
        $this.Size = $FormatObject.size
        $this.BitRate = $FormatObject.bit_rate
        $this.ProbeScore = $FormatObject.probe_score
        $this.Tags = @{}
        foreach ($kvp in $FormatObject.tags?.psobject?.Properties) {
            $this.Tags.Add($kvp.Name, $kvp.Value)
        }
        $this.Raw = $FormatObject
    }

    [string] ToString() {
        return "File $($this.Title): $($this.Path)"
    }
}
