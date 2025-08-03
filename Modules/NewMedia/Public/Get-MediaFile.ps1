<#
.SYNOPSIS
Get-MediaFile - Get media information from a file

.DESCRIPTION
Get-MediaFile is a function that gets media information from a file.

.PARAMETER Path
The path to the file to get media information from.
#>
function Get-MediaFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$InputPath
    )
    process {
        foreach ($filePath in $InputPath) {
            try {
                $inputPath = Get-Path -Path $filePath -ValidatePath File -PathType Absolute

                $ffprobeArgs = @('-show_format', '-show_chapters', '-show_streams', '-i', $inputPath)

                $result = Invoke-FFProbe -Arguments $ffprobeArgs
                if ($result.ExitCode -ne 0) {
                    Write-Message "Failed to get media information for $($inputPath.FullName):`nFFProbe failed with exit code $($result.ExitCode): $($result.ErrorOutput)" -Type Error
                    throw "Failed to get media information for $($inputPath.FullName):`nFFProbe failed with exit code $($result.ExitCode): $($result.ErrorOutput)"
                }

                $format = [MediaFormat]::new($result.Json.format)

                Write-Message "FFProbe returned $($result.Json.chapters.Count) total chapters" -Type Verbose
                $chapters = New-Object System.Collections.Generic.List[MediaChapter]
                foreach ($chapter in $result.Json.chapters) {
                    $chapters.Add([MediaChapter]::new($chapter))
                }

                Write-Message "FFProbe returned $($result.Json.streams.Count) total streams" -Type Verbose
                $streams = New-Object System.Collections.Generic.List[MediaStream]
                foreach ($stream in $result.Json.streams) {
                    $streams.Add([MediaStream]::new($stream))
                }

                [MediaFile]::new($inputPath, $format, $chapters.ToArray(), $streams.ToArray(), $result.Json)
            }
            catch {
                Write-Message "Error processing file '$filePath': $($_.Exception.Message)" -Type Error
                if ($ErrorActionPreference -eq 'Stop') {
                    throw
                }
            }
        }
    }
}
