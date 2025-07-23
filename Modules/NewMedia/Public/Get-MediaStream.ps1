<#
.SYNOPSIS
Get-MediaStream - Get media tracks from a file

.DESCRIPTION
Get-MediaStream is a function that gets media tracks from a file.

.PARAMETER Path
The path to the file to get media tracks from.
#>
function Get-MediaStream {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter()]
        [ValidateSet('Video', 'Audio', 'Subtitle', 'Data', 'All')]
        [string]$TrackType = 'All'
    )
    process {
        $inputPath = Get-Path -Path $Path -ValidatePath File -PathType Absolute
        $result = Invoke-FFProbe -Arguments @('-show_streams', '-i', $inputPath)
        if ($result.ExitCode -ne 0) {
            Write-Message "Failed to get media track for $($inputPath.FullName):`nFFProbe failed with exit code $($result.ExitCode): $($result.ErrorOutput)" -Type Error
            throw "Failed to get media track for $($inputPath.FullName):`nFFProbe failed with exit code $($result.ExitCode): $($result.ErrorOutput)"
        }

        Write-Message "FFProbe returned $($result.Json.streams.Count) total streams" -Type Debug
        $streams = New-Object System.Collections.Generic.List[MediaStream]
        foreach ($stream in $result.Json.streams) {
            if ($TrackType -eq 'All' -or $stream.codec_type -eq $TrackType.ToLowerInvariant()) {
                $tracks.Add([MediaStream]::new($stream))
            }
        }
        Write-Message "Function returning $($tracks.Count) tracks" -Type Verbose
        return $tracks.ToArray()
        return $streams.ToArray()
    }
}
