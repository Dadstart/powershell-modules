function Rename-FileAudioStream {
    <#
    .SYNOPSIS
        Renames audio streams in video files to match their type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$File,
        [Parameter(Mandatory)]
        [string[]]$Titles,
        [Parameter(Mandatory)]
        [string]$TempDirectory
    )
    begin {
        if (-not (Test-Path $TempDirectory)) {
            Write-Message "TempDirectory does not exist: $TempDirectory" -Type Error
        }
        if (-not (Test-Path $File)) {
            Write-Message "File does not exist: $File" -Type Error
        }
    }
    process {
        Write-Message "Renaming audio streams in $File" -Type Verbose
        Write-Message "File: $File" -Type Debug
        Write-Message "TempDirectory: $TempDirectory" -Type Debug
        Write-Message "Titles count: $($Titles.Count)" -Type Debug
        # Get a temp file and copy the original file to it
        $tempFileName = Get-Path -Path $File -PathType Leaf
        $tempFileFullName = Get-Path -Path $TempDirectory, $tempFileName -PathType Absolute
        try {
            Write-Message "Copying $File to $tempFileFullName" -Type Verbose
            Copy-Item -Path $File -Destination $tempFileFullName -Force
            #   ffmpeg -i input.mp4 -map 0 -c copy -metadata:s:a:[Index] title [Title] output.mp4
            $ffmpegArgs = @(
                '-i', "`"$tempFileFullName`"",
                '-map', '0'
            )
            for ($i = 0; $i -lt $Titles.Count; $i++) {
                $title = $Titles[$i]
                Write-Message "Adding title metadata '$title' to stream $i" -Type Verbose
                if (-not $title) {
                    Write-Message "Stream $i has no title" -Type Warning
                    continue
                }
                $ffmpegArgs += @(
                    '-metadata:s:a:' + $i,
                    "title=`"$($title)`""
                )
            }
            $ffmpegArgs += @(
                '-c', 'copy',
                '-y',
                "`"$File`""
            )
            Write-Message "Invoking FFmpeg with arguments: $ffmpegArgs" -Type Verbose
            Invoke-FFmpeg -Arguments $ffmpegArgs | Out-Null
        }
        finally {
            if (Test-Path $tempFileFullName) {
                Write-Message "Deleting $tempFileFullName" -Type Debug
                Remove-Item -Path $tempFileFullName -Force
            }
        }
    }
    end {
    }
}
