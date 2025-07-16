function Get-AudioMetadataMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath
    )
    begin {
        $allResults = @()
    }
    process {
        try {
            Write-Message "Processing file: $InputPath" -Type Verbose
            # Validate input file
            if (-not (Test-Path -Path $InputPath -PathType Leaf -ErrorAction SilentlyContinue)) {
                Write-Message "Input file does not exist: $InputPath" -Type Error
                return
            }
            # Check if ffprobe is available
            if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
                Write-Message "ffprobe is not available in PATH" -Type Error
                return
            }
            $ffprobeOutput = Invoke-FFProbe -Arguments $ffprobeArgs
            if ($ffprobeOutput.ExitCode -ne 0) {
                Write-Message "ffprobe failed with exit code: $($ffprobeOutput.ExitCode)" -Type Verbose
                Write-Message "ffprobe failed to analyze input file (exit code: $($ffprobeOutput.ExitCode)): $($ffprobeOutput.Error -join "`n")" -Type Error
                return $null
            }
            else {
                Write-Message "ffprobe completed successfully" -Type Verbose
            }
            $metadataArgs = @()
            for ($i = 0; $i -lt $ffprobeOutput.Json.streams.Count; $i++) {
                $stream = $ffprobeOutput.Json.streams[$i]
                $tags   = $stream.tags
                if ($tags) {
                    if ($tags.language) {
                        $metadataArgs += "-metadata:s:a:$i"
                        $metadataArgs += "language=$($tags.language)"
                    }
                    if ($tags.title) {
                        $metadataArgs += "-metadata:s:a:$i"
                        $metadataArgs += "title=$($tags.title)"
                    }
                }
            }
            # Add file info to results
            $result = [PSCustomObject]@{
                File = $InputPath
                Arguments = $metadataArgs
            }
            $allResults += $result
        }
        catch {
            Write-Message "Failed to get audio metadata map for $InputPath`: $($_.Exception.Message)" -Type Error
        }
    }
    end {
        return $allResults
    }
} 
