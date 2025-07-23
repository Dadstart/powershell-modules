class MediaChapter {
    [string] $Id
    [string] $TimeBase
    [double] $Start
    [string] $StartTime
    [double] $End
    [string] $EndTime
    [string] $Title
    [hashtable] $Tags
    [psobject] $Raw

    MediaChapter([psobject]$Chapter) {
        $this.Id = $Chapter.id
        $this.TimeBase = $Chapter.time_base
        $this.Start = $Chapter.start
        $this.StartTime = $Chapter.start_time
        $this.End = $Chapter.end
        $this.EndTime = $Chapter.end_time
        $this.Title = $Chapter.tags.title
        $this.Tags = @{}
        foreach ($kvp in $Chapter.tags?.psobject?.Properties) {
            Write-Host "`$key: $($kvp.Name); `$value: $($kvp.Value)" -ForegroundColor White
            $this.Tags.Add($kvp.Name, $kvp.Value)
        }
        $this.Raw = $Chapter
    }

    [double] get_Duration() {
        return [double]$this.EndTime - [double]$this.StartTime
    }

    hidden [double] GetDuration() {
        $durationSec = $this.get_Duration()

        # Convert to TimeSpan (via milliseconds)
        $durationMs = [math]::Round($durationSec * 1000)
        $timeSpan = [TimeSpan]::FromMilliseconds($durationMs)

        # Format output as hh:mm:ss.fff
        return $timeSpan.ToString('hh\:mm\:ss\.fff')
    }

    [string] ToString() {
        [decimal]
        return "Chapter $($this.Title): $($this.GetDuration())"
    }
}
