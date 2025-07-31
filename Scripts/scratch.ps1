if ($false) {

    Get-ChildItem *.mkv | ForEach-Object { Get-MediaFile $_ } | Set-Variable files
    foreach ($file in $files) {
        $files[0].Streams[0].Raw.width, $files[0].Streams[0].Raw.height
    }

    $files | Where-Object { $_.Streams[0].Raw.width -eq 1080 }
}


# Define input/output
# 720:464:0:6
# 720:352:0:62
function Test-CropValues {
    <#
    .SYNOPSIS
        Tests multiple crop values on a video file to find the optimal cropping parameters.
    .DESCRIPTION
        This function tests various crop values on a video file and generates preview images
        for each crop value to help determine the best cropping parameters.
    .PARAMETER InputFile
        Path to the input video file.
    .PARAMETER CropValues
        Array of crop values to test in format "width:height:x:y".
        If not provided, uses default common letterboxing scenarios.
    .PARAMETER OutputPrefix
        Prefix for the output preview images.
    .EXAMPLE
        Test-CropValues -InputFile "movie.mkv" -CropValues @("720:352:0:62", "720:360:0:60")
    .EXAMPLE
        Test-CropValues -InputFile "movie.mkv" -OutputPrefix "my_crop_test"
    .OUTPUTS
        [PSCustomObject[]] Array of results with crop values, output files, and success status.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$InputFile,
        [string[]]$CropValues = @(),
        [string]$OutputPrefix = "crop_test"
    )
    begin {
        # Automatically pass -Verbose and -Debug to called functions
        @('Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        Write-Message "Testing multiple crop values for: $InputFile" -Type Processing

        if ($CropValues.Count -eq 0) {
            # Default test values - common letterboxing scenarios
            $CropValues = @(
                '720:352:0:62',    # Original detected value
                '720:352:0:60',    # Slightly less top crop
                '720:352:0:58',    # Even less top crop
                '720:352:0:64',    # Slightly more top crop
                '720:352:0:66',    # More top crop
                '720:360:0:60',    # Different height
                '720:368:0:56'     # Different height
            )
        }

        $results = @()

        foreach ($cropValue in $CropValues) {
            $outputFile = "${OutputPrefix}_${cropValue.Replace(':', '_')}.jpg"

            Write-Message "Testing crop: $cropValue" -Type Info

            $ffmpegArgs = @(
                '-ss', '00:01:00',
                '-t', '5',
                '-i', $InputFile,
                '-vf', "crop=$cropValue,scale=480:-1",
                '-vframes', '1',
                '-y',
                $outputFile
            )

            $ffmpegResult = Invoke-FFMpeg -Arguments $ffmpegArgs

            $result = [PSCustomObject]@{
                CropValue  = $cropValue
                OutputFile = $outputFile
                Success    = ($ffmpegResult.ExitCode -eq 0)
                Error      = if ($ffmpegResult.ExitCode -ne 0) {
                    $ffmpegResult.Error 
                }
                else {
                    $null 
                }
            }

            $results += $result

            if ($result.Success) {
                Write-Message "✅ Created: $outputFile" -Type Success
            }
            else {
                Write-Message "❌ Failed: $($result.Error)" -Type Error
            }
        }

        Write-Message 'Crop testing complete. Check the generated preview images.' -Type Info
        return $results
    }
}

function Test-CropPreview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$InputFile,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\d+:\d+:\d+:\d+$')]
        [string]$CropValue,
        [string]$OutputFile = "crop_preview.jpg",
        [ValidateRange(1, 60)]
        [int]$PreviewDuration = 5
    )
    begin {
        # Automatically pass -Verbose and -Debug to called functions
        @('Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        Write-Message "Creating crop preview for: $InputFile" -Type Processing
        Write-Message "Crop value: $CropValue" -Type Info

        # Create a preview image with the crop applied
        $ffmpegArgs = @(
            '-ss', '00:01:00',  # Start at 1 minute
            '-t', $PreviewDuration.ToString(),
            '-i', $InputFile,
            '-vf', "crop=$CropValue,scale=480:-1",  # Apply crop and scale down for preview
            '-vframes', '1',  # Extract just one frame
            '-y',  # Overwrite output file
            $OutputFile
        )

        Write-Message "Creating preview with arguments: $($ffmpegArgs -join ' ')" -Type Info
        $ffmpegResult = Invoke-FFMpeg -Arguments $ffmpegArgs

        if ($ffmpegResult.ExitCode -eq 0) {
            Write-Message "✅ Crop preview created: $OutputFile" -Type Success
            Write-Message "📁 Preview saved to: $(Resolve-Path $OutputFile)" -Type Info
            return $true
        }
        else {
            Write-Message "❌ Failed to create crop preview: $($ffmpegResult.Error)" -Type Error
            return $false
        }
    }
}

function Get-CropValue {
    <#
    .SYNOPSIS
        Automatically detects crop parameters for a video file using FFmpeg's cropdetect filter.
    .DESCRIPTION
        This function analyzes a video file at multiple sample points to detect letterboxing
        or pillarboxing and returns the optimal crop parameters. It uses FFmpeg's cropdetect
        filter with retry logic and validation to ensure reliable results.
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
        [int]$CropThreshold = 20,
        [ValidateRange(1, 60)]
        [int]$SampleDuration = 10,
        [string[]]$SamplePoints = @('00:00:00', '00:00:30', '00:01:00', '00:02:00'),
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
            $errorMsg = if ($probeResult.ErrorContent) { $probeResult.ErrorContent } else { $probeResult.Error }
            Write-Message "Failed to probe video: $errorMsg" -Type Error
            return $null
        }

        try {
            $videoInfo = if ($probeResult.Json) { $probeResult.Json } else { $probeResult.Output | ConvertFrom-Json }
            $width = $videoInfo.streams[0].width
            $height = $videoInfo.streams[0].height
            Write-Message "Original video dimensions: ${width}x${height}" -Type Info
        }
        catch {
            Write-Message "Failed to parse video info: $($_.Exception.Message)" -Type Error
            return $null
        }

        # Collect crop values from multiple sample points
        $allCropValues = @()
        $maxRetries = 3

        # Use fewer sample points in quick mode
        $samplePointsToUse = if ($QuickMode) {
            $SamplePoints[0..1] 
        }
        else {
            $SamplePoints 
        }

        foreach ($samplePoint in $samplePointsToUse) {
            Write-Message "Sampling at $samplePoint..." -Type Info
            $retryCount = 0
            $sampleSuccess = $false

            do {
                $retryCount++
                try {
                    # Improved cropdetect with better parameters
                    $ffmpegArgs = @(
                        '-ss', $samplePoint,
                        '-t', $SampleDuration.ToString(),
                        '-i', $InputFile,
                        '-vf', "cropdetect=mode=mvedges:limit=$CropThreshold`:round=1:reset=1",
                        '-f', 'null',
                        '-'
                    )

                    Write-Message "Running cropdetect with arguments: $($ffmpegArgs -join ' ')" -Type Info
                    $ffmpegResult = Invoke-FFMpeg -Arguments $ffmpegArgs -Verbosity 'info'
                    $cropDetect = $ffmpegResult.Output

                    # Extract all crop values from this sample
                    $cropMatches = $cropDetect | Select-String 'crop=\d+:\d+:\d+:\d+'

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
                        Write-Message "No crop values detected at $samplePoint (attempt $retryCount/$maxRetries)" -Type Warning
                    }
                }
                catch {
                    Write-Message "Error sampling at $samplePoint (attempt $retryCount/$maxRetries): $($_.Exception.Message)" -Type Error
                }
            } while (-not $sampleSuccess -and $retryCount -lt $maxRetries)

            if (-not $sampleSuccess) {
                Write-Message "Failed to detect crop values at $samplePoint after $maxRetries attempts" -Type Warning
            }
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
                $warnings += "Crop extends beyond video width"
                $isValid = $false
            }

            if ($cropY + $cropHeight -gt $height) {
                $warnings += "Crop extends beyond video height"
                $isValid = $false
            }

            # Check if crop is too small (less than 10% of original)
            if ($cropWidth * $cropHeight -lt $width * $height * 0.1) {
                $warnings += "Crop area is less than 10% of original video area"
                $isValid = $false
            }

            if ($warnings.Count -gt 0) {
                Write-Message "Crop validation warnings:" -Type Warning
                foreach ($warning in $warnings) {
                    Write-Message "  - $warning" -Type Warning
                }

                if (-not $isValid) {
                    Write-Message "Crop validation failed. Consider manual crop or adjusting threshold." -Type Error
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

function Add-CropValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [psobject]$MediaFile
    )
    begin {
        # Automatically pass -Verbose and -Debug to called functions
        # Note: Invoke-FFmpeg doesn't accept -Verbose/-Debug directly, so we exclude it
        @('Get-CropValue', 'Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        $cropValue = Get-CropValue -InputFile $MediaFile.Path
        Add-Member -InputObject $MediaFile -MemberType NoteProperty -Name 'CropValue' -Value $cropValue
    }
}


function Invoke-CropItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [psobject]$MediaFile,
        [Parameter(Mandatory)]
        [string]$OutputFile,
        [string]$VideoCodec = 'libx264',
        [string]$Preset = 'veryslow',
        [int]$CRF = 17,
        [switch]$CopyAudio = $true
    )
    begin {
        # Automatically pass -Verbose and -Debug to called functions
        # Note: Invoke-FFmpeg doesn't accept -Verbose/-Debug directly, so we exclude it
        @('Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        Write-Message "🔁 Applying crop to $($MediaFile.Path)" -Type Processing
        # Apply crop and encode with configurable settings
        $ffmpegArgs = @(
            '-i', $MediaFile.Path,
            '-vf', "crop=$($MediaFile.CropValue)",
            '-c:v', $VideoCodec,
            '-preset', $Preset,
            '-crf', $CRF.ToString()
        )

        if ($CopyAudio) {
            $ffmpegArgs += @('-c:a', 'copy')
        }

        $ffmpegArgs += $OutputFile
        Write-Message "📝 Running FFmpeg with arguments: $($ffmpegArgs -join ' ')" -Type Info
        # Use Invoke-FFMpeg instead of direct ffmpeg call for better error handling
        $ffmpegResult = Invoke-FFMpeg -Arguments $ffmpegArgs
        if ($ffmpegResult.ExitCode -ne 0) {
            Write-Message "❌ Failed to crop $($MediaFile.Path)" -Type Error
            Write-Message $ffmpegResult.Error -Type Error
            return
        }

        Write-Message "✅ Crop complete: $OutputFile" -Type Success
    }
}

function ConvertTo-Cropped {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$InputFolder,
        [Parameter(Mandatory, Position = 1)]
        [string]$OutputFolder
    )
    begin {
        # Automatically pass -Verbose and -Debug to called functions
        # Note: Invoke-FFmpeg doesn't accept -Verbose/-Debug directly, so we exclude it
        @('Add-CropValue', 'Invoke-CropItem', 'Get-CropValue', 'Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }

        if (-not (Test-Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder | Out-Null
        }

        $mediaFiles = Get-ChildItem $InputFolder -Filter *.mkv | ForEach-Object { Get-MediaFile $_ }
        Write-Message "📽️ Found $($mediaFiles.Count) files" -Type Info

        $cropped = New-Object System.Collections.Generic.List[object]
        $skipped = New-Object System.Collections.Generic.List[object]
    }
    process {
        $totalFiles = $mediaFiles.Count
        $currentFile = 0

        foreach ($mediaFile in $mediaFiles) {
            $currentFile++
            $inputFile = $mediaFile.Path
            $fileName = Get-Path $inputFile -PathType Leaf
            $outputFile = Get-Path $OutputFolder, $fileName
            #$outputFile = [System.IO.Path]::ChangeExtension($inputFile, '_cropped.mkv')

            Write-Message "📝 Processing $fileName -> $outputFile ($currentFile/$totalFiles)" -Type Info

            Add-CropValue $mediaFile
            if ($mediaFile.CropValue) {
                Write-Message "🎯 Crop value: $($mediaFile.CropValue)" -Type Info
                if ($PSCmdlet.ShouldProcess($inputFile, "Crop video to $($mediaFile.CropValue)")) {
                    Invoke-CropItem $mediaFile -OutputFile $outputFile
                }
                $cropped.Add($mediaFile)
            }
            else {
                Write-Message '🚫 No crop value found' -Type Warning
                $skipped.Add($mediaFile)
            }
        }
    }
    end {
        Write-Message '✅ Done with all files' -Type Success
        Write-Message "📂 Cropped $($cropped.Count) files" -Type Success
        $skippedFiles = ($skipped | ForEach-Object { $_.Path }) -join '`n'
        Write-Message "📂 Skipped $($skipped.Count) files:" -Type Info
        Write-Message "`t$($skippedFiles -join '`n`t')" -Type Info

        return [PSCustomObject]@{
            MediaFiles = $mediaFiles
            Cropped    = $cropped
            Skipped    = $skipped
        }
    }
}

function Get-CropSummary {
    <#
    .SYNOPSIS
        Provides summary statistics for crop operations.
    .DESCRIPTION
        This function analyzes crop results and provides detailed statistics including
        success rates, common crop values, and recommendations.
    .PARAMETER Results
        Results object from ConvertTo-Cropped function.
    .EXAMPLE
        $results = ConvertTo-Cropped -InputFolder "C:\Input" -OutputFolder "C:\Output"
        Get-CropSummary -Results $results
    .OUTPUTS
        [PSCustomObject] Summary statistics and recommendations.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$Results
    )

    $totalFiles = $Results.MediaFiles.Count
    $croppedFiles = $Results.Cropped.Count
    $skippedFiles = $Results.Skipped.Count
    $successRate = if ($totalFiles -gt 0) {
        [math]::Round(($croppedFiles / $totalFiles) * 100, 2) 
    }
    else {
        0 
    }

    # Analyze crop values
    $cropValues = $Results.Cropped | ForEach-Object { $_.CropValue } | Group-Object | Sort-Object Count -Descending

    $summary = [PSCustomObject]@{
        TotalFiles         = $totalFiles
        CroppedFiles       = $croppedFiles
        SkippedFiles       = $skippedFiles
        SuccessRate        = $successRate
        MostCommonCrop     = if ($cropValues.Count -gt 0) {
            $cropValues[0].Name 
        }
        else {
            $null 
        }
        CropValueFrequency = $cropValues
        Recommendations    = @()
    }

    # Generate recommendations
    if ($successRate -lt 80) {
        $summary.Recommendations += "Consider adjusting CropThreshold parameter for better detection"
    }

    if ($cropValues.Count -gt 1) {
        $summary.Recommendations += "Multiple crop values detected - consider manual verification"
    }

    if ($skippedFiles -gt 0) {
        $summary.Recommendations += "Some files were skipped - check input files for issues"
    }

    return $summary
}

$prevScratchVer = $global:scratchVer
$scratchVer = 18
Write-Host "🔄 Scratch version: $prevScratchVer 🔒 $scratchVer ➡️ $($global:scratchVer) ✅" -ForegroundColor Cyan
