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
        Write-Host "FormatObject:`n$($FormatObject)" -ForegroundColor Green
        Write-Host "FormatObject.tags:`n$($FormatObject.tags)" -ForegroundColor Cyan
        Write-Host "FormatObject.tags.psobject:`n$($FormatObject.tags.psobject)" -ForegroundColor Cyan
        Write-Host "FormatObject.tags.psobject.Properties:`n$($FormatObject.tags.psobject.Properties -join ', ')" -ForegroundColor Cyan
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
        Write-Host "FormatObject.tags:`n$($FormatObject.tags)" -ForegroundColor Green
        Write-Host "FormatObject.tags.psobject:`n$($FormatObject.tags.psobject)" -ForegroundColor Cyan
        Write-Host "FormatObject.tags.psobject.Properties:`n$($FormatObject.tags.psobject.Properties -join ', ')" -ForegroundColor Cyan
        foreach ($kvp in $FormatObject.tags?.psobject?.Properties) {
            Write-Host "`$key: $($kvp.Name); `$value: $($kvp.Value)" -ForegroundColor White
            $this.Tags.Add($kvp.Name, $kvp.Value)
        }
        $this.Raw = $FormatObject
    }

    [string] ToString() {
        return "File $($this.Title): $($this.Path)"
    }
}