function Get-CropValue {
    <#
    .SYNOPSIS
        Automatically detects crop parameters for a video file using FFmpeg's cropdetect filter.
    .DESCRIPTION
        This function analyzes a video file at multiple sample points to detect letterboxing
        or pillarboxing and returns the optimal crop parameters. It uses FFmpeg's cropdetect
        filter to ensure reliable results.
    .PARAMETER InputFile
        Path to the input video file.
    .PARAMETER CropThreshold
        Threshold for crop detection (1-100). Lower values are more sensitive.
    .PARAMETER SampleDuration
        Duration in seconds to sample at each point (1-60).
    .PARAMETER SamplePoints
        Array of time points to sample for crop detection.
    .EXAMPLE
        Get-CropValue -InputFile "movie.mkv"
    .EXAMPLE
        Get-CropValue -InputFile "movie.mkv" -CropThreshold 15 -SampleDuration 15
    .OUTPUTS
        [string] Crop value in format "width:height:x:y" or $null if detection fails.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$InputFile,
        [ValidateRange(1, 100)]
        [int]$CropThreshold = 17,
        [ValidateRange(1, 60)]
        [int]$SampleDuration = 10,
        [string[]]$SamplePoints = @('00:00:01', '00:00:31', '00:01:01', '00:02:01'),
        [switch]$QuickMode = $false
    )
    begin {
        # Automatically pass -Verbose and -Debug to called functions
        # Note: Invoke-FFmpeg doesn't accept -Verbose/-Debug directly, so we exclude it
        @('Invoke-FFmpeg') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        # Ensure CropThreshold has a valid value
        if (-not $CropThreshold) {
            # Why is this needed? This parameter has a ValidateRange(1, 100) attribute
            Write-Warning '⚠️ CropThreshold is not set, using default value of 20'
            $CropThreshold = 20
        }

        Write-Message 'Detecting crop parameters with improved algorithm...' -Type Processing

        # Get video dimensions first
        $probeArgs = @(
            '-show_streams',
            '-select_streams', 'v:0',
            $InputFile
        )

        Write-Message 'Getting video dimensions...' -Type Info
        $probeResult = Invoke-FFProbe -Arguments $probeArgs
        if ($probeResult.ExitCode -ne 0) {
            $errorMsg = if ($probeResult.ErrorContent) {
                $probeResult.ErrorContent 
            }
            else {
                $probeResult.Error 
            }
            Write-Message "Failed to probe video: $errorMsg" -Type Error
            return $null
        }

        $videoInfo = $probeResult.Json ?? ($probeResult.Output | ConvertFrom-Json)
        $width = $videoInfo.streams[0].width
        $height = $videoInfo.streams[0].height
        Write-Message "Original video dimensions: ${width}x${height}" -Type Info

        # Collect crop values from multiple sample points
        $allCropValues = @()

        # Use fewer sample points in quick mode
        $samplePointsToUse = if ($QuickMode) {
            $SamplePoints[0..1]
        }
        else {
            $SamplePoints
        }

        foreach ($samplePoint in $samplePointsToUse) {
            Write-Message "Sampling at $samplePoint..." -Type Info
            $sampleSuccess = $false

            # Improved cropdetect with better parameters
            # ffmpeg -ss 00:00:01 -t 10 -i .\Action-deleted.mkv -vf "cropdetect=limit=17:round=2:reset=0" -an -vsync 0 -f null -
            $ffmpegArgs = @(
                '-ss', $samplePoint,
                '-t', $SampleDuration,
                '-i', $InputFile,
                '-vf', "cropdetect=limit=$CropThreshold`:round=2:reset=0",
                '-an',
                '-vsync', '0',
                '-f', 'null',
                '-'
            )
            Write-Message "Running cropdetect with arguments: $($ffmpegArgs -join ' ')" -Type Info
            $ffmpegResult = Invoke-FFMpeg -Arguments $ffmpegArgs -Verbosity 'info'
            $cropDetect = $ffmpegResult.ErrorOutput -split "`r`n"

            # Extract all crop values from this sample
            $cropMatches = $cropDetect | Select-String 'Parsed_cropdetect'

            if ($cropMatches) {
                foreach ($match in $cropMatches) {
                    $cropValue = $match.ToString() -replace '.*crop=', ''
                    if ($cropValue -match '^\d+:\d+:\d+:\d+$') {
                        $allCropValues += $cropValue
                    }
                }
                $sampleSuccess = $true
            }
            else {
                Write-Message "No crop values detected at $samplePoint" -Type Warning
            }
        }

        if (-not $sampleSuccess) {
            Write-Message "Failed to detect crop values at $samplePoint" -Type Warning
        }

        if ($allCropValues.Count -eq 0) {
            Write-Message 'No crop parameters detected in any sample' -Type Warning
            return $null
        }

        # Find the most common crop value (consensus)
        $cropCounts = $allCropValues | Group-Object | Sort-Object Count -Descending
        $mostCommonCrop = $cropCounts[0].Name

        Write-Message "Found $($allCropValues.Count) crop values across $($SamplePoints.Count) samples" -Type Info
        Write-Message "Most common crop value: $mostCommonCrop (appears $($cropCounts[0].Count) times)" -Type Info

        # Parse the crop values to validate
        if ($mostCommonCrop -match '^(\d+):(\d+):(\d+):(\d+)$') {
            $cropWidth = [int]$Matches[1]
            $cropHeight = [int]$Matches[2]
            $cropX = [int]$Matches[3]
            $cropY = [int]$Matches[4]

            # Validation checks
            $isValid = $true
            $warnings = @()

            # Check if crop dimensions are reasonable
            if ($cropWidth -lt $width * 0.5) {
                $warnings += "Crop width ($cropWidth) is less than 50% of original width ($width)"
                $isValid = $false
            }

            if ($cropHeight -lt $height * 0.5) {
                $warnings += "Crop height ($cropHeight) is less than 50% of original height ($height)"
                $isValid = $false
            }
            if ($cropX + $cropWidth -gt $width) {
                $warnings += 'Crop extends beyond video width'
                $isValid = $false
            }

            if ($cropY + $cropHeight -gt $height) {
                $warnings += 'Crop extends beyond video height'
                $isValid = $false
            }

            # Check if crop is too small (less than 10% of original)
            if ($cropWidth * $cropHeight -lt $width * $height * 0.1) {
                $warnings += 'Crop area is less than 10% of original video area'
                $isValid = $false
            }

            if ($warnings.Count -gt 0) {
                Write-Message 'Crop validation warnings:' -Type Warning
                foreach ($warning in $warnings) {
                    Write-Message "  - $warning" -Type Warning
                }

                if (-not $isValid) {
                    Write-Message 'Crop validation failed. Consider manual crop or adjusting threshold.' -Type Error
                    return $null
                }
            }

            Write-Message "Crop validation passed. Final crop: ${cropWidth}x${cropHeight}+${cropX}+${cropY}" -Type Success
            return $mostCommonCrop
        }
        else {
            Write-Message "Invalid crop format: $mostCommonCrop" -Type Error
            return $null
        }
    }
}
