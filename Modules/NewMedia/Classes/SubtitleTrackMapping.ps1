<#
.SYNOPSIS
SubtitleTrackMapping - A class that represents a subtitle track mapping
.DESCRIPTION
SubtitleTrackMapping is a class that represents a subtitle track mapping.
.PARAMETER SourceIndex
#>
class SubtitleTrackMapping {
    [int]     $SourceIndex
    [string]  $Language
    [string]  $Codec       # Usually 'hdmv_pgs_subtitle'
    [string]  $Extension   # For sidecar file, e.g. '.srt'
    [string]  $OutputPath
    SubtitleTrackMapping(
        [int]    $sourceIndex,
        [string] $language,
        [string] $codec,
        [string] $extension,
        [string] $outputPath
    ) {
        $this.SourceIndex = $sourceIndex
        $this.Language = $language
        $this.Codec = $codec
        $this.Extension = $extension
        $this.OutputPath = $outputPath
    }
    [string] ToString() {
        return "Subtitle $($this.SourceIndex) [$($this.Language)] → $($this.OutputPath)"
    }
    [string[]] ToFfmpegArgs([string]$InputFile) {
        $ffmpegArgs = @('-i', $InputFile)
        $ffmpegArgs += '-map', "0:s:$($this.SourceIndex)"
        $ffmpegArgs += '-c:s', 'srt' # You may dynamically map based on $this.Extension
        $ffmpegArgs += $this.OutputPath
        return $ffmpegArgs
    }
}
