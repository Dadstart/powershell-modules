class MediaFile {
    [string] $Path
    [MediaFormat] $Format
    [MediaChapter[]] $Chapters
    [MediaStream[]] $Streams
    [psobject] $Raw

    MediaFile(
        [string] $Path,
        [MediaFormat] $Format,
        [MediaChapter[]] $Chapters,
        [MediaStream[]] $Streams,
        [psobject] $Raw
    ) {
        $this.Path = $Path
        $this.Format = $Format
        $this.Chapters = $Chapters
        $this.Streams = $Streams
        $this.Raw = $Raw
    }

    [string] ToString() {
        return "File $($this.Title): $($this.Path)"
    }
}
