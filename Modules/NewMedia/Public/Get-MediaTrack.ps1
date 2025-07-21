. $PSScriptRoot\..\Classes\MediaTrack.ps1

function Get-MediaTrack {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter()]
        [ValidateSet('Video', 'Audio', 'Subtitle', 'Data', 'All')]
        [string]$TrackType = 'All',
        [Parameter()]
        [switch]$InludeRaw
    )

    process {
        $inputPath = Get-Path -Path $Path -ValidatePath File -PathType Absolute
        Test-FFMpegInstalled -Throw

        $result = Invoke-FFProbe -Arguments @('-show_streams', '-i', $inputPath)
        if ($result.Failure) {
            Write-Message "Failed to get media track for $($inputPath.FullName):`nFFProbe failed with exit code $($result.ExitCode): $($result.ErrorOutput)" -Type Error
            return $null
        }

        $streams = $result.Json.streams | switch ($TrackType) {
            switch ($TrackType) {
                'Video' {
                    Where-Object { $_.codec_type -eq 'video' }
                }
                'Audio' {
                    Where-Object { $_.codec_type -eq 'audio' }
                }
                'Subtitle' {
                    Where-Object { $_.codec_type -eq 'subtitle' }
                }
                'Data' {
                    Where-Object { $_.codec_type -eq 'data' }
                }
                'All' {
                    $_
                }
            }
        }

        $tracks = @()
        foreach ($stream in $streams) {
            $track = [MediaTrack]::new($stream)
            $tracks += $track
            if (-not $InludeRaw) {
                $track.PSObject.Properties.Remove('Raw')
            }
            Write-Message $track -Type Verbose
        }

        return $tracks
    }
}