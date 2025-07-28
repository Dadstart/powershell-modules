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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
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
                CropValue = $cropValue
                OutputFile = $outputFile
                Success = ($ffmpegResult.ExitCode -eq 0)
                Error = if ($ffmpegResult.ExitCode -ne 0) { $ffmpegResult.Error } else { $null }
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
        [string]$InputFile,
        [Parameter(Mandatory)]
        [string]$CropValue,
        [string]$OutputFile = "crop_preview.jpg",
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
    [CmdletBinding()]
    param (
        [string]$inputFile,
        [int]$CropThreshold = 20,
        [int]$SampleDuration = 10,
        [string[]]$SamplePoints = @('00:01:00', '00:05:00', '00:10:00', '00:15:00')
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
        Write-Message 'Detecting crop parameters with improved algorithm...' -Type Processing

        # Get video dimensions first
        $probeArgs = @(
            '-v', 'quiet',
            '-print_format', 'json',
            '-show_streams',
            '-select_streams', 'v:0',
            $inputFile
        )

        Write-Message 'Getting video dimensions...' -Type Info
        $probeResult = Invoke-FFMpeg -Arguments $probeArgs
        if ($probeResult.ExitCode -ne 0) {
            Write-Message "Failed to probe video: $($probeResult.Error)" -Type Error
            return $null
        }

        try {
            $videoInfo = $probeResult.Output | ConvertFrom-Json
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

        foreach ($samplePoint in $SamplePoints) {
            Write-Message "Sampling at $samplePoint..." -Type Info

            # Improved cropdetect with better parameters
            $ffmpegArgs = @(
                '-ss', $samplePoint,
                '-t', $SampleDuration.ToString(),
                '-i', $inputFile,
                '-vf', "cropdetect=mode=mvedges:limit=$CropThreshold:round=1:reset=1",
                '-f', 'null'
            )

            Write-Message "Running cropdetect with arguments: $($ffmpegArgs -join ' ')" -Type Info
            $ffmpegResult = Invoke-FFMpeg -Arguments $ffmpegArgs
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
        $cropValue = Get-CropValue -inputFile $MediaFile.Path
        Add-Member -InputObject $MediaFile -MemberType NoteProperty -Name 'CropValue' -Value $cropValue
    }
}


function Invoke-CropItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [psobject]$MediaFile,
        [Parameter(Mandatory)]
        [string]$OutputFile
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
        # Apply crop and encode with x264
        $ffmpegArgs = @(
            '-i', $MediaFile.Path,
            '-vf', "crop=$($MediaFile.CropValue)",
            '-c:v', 'libx264',
            '-preset', 'veryslow',
            '-crf', '17',
            '-c:a', 'copy',
            $OutputFile
        )
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
        Write-Host "📽️ Found $($mediaFiles.Count) files" -ForegroundColor Cyan

        $cropped = New-Object System.Collections.Generic.List[object]
        $skipped = New-Object System.Collections.Generic.List[object]
    }
    process {
        foreach ($mediaFile in $mediaFiles) {
            $inputFile = $mediaFile.Path
            $fileName = Get-Path $inputFile -PathType Leaf
            $outputFile = Get-Path $OutputFolder, $fileName
            #$outputFile = [System.IO.Path]::ChangeExtension($inputFile, '_cropped.mkv')
            Write-Host "📝 Processing $($fileName) -> $($outputFile)" -ForegroundColor Cyan
            Add-CropValue $mediaFile
            if ($mediaFile.CropValue) {
                Write-Host "🎯 Crop value: $($mediaFile.CropValue)" -ForegroundColor Gray
                if ($PSCmdlet.ShouldProcess($inputFile, "Crop video to $($mediaFile.CropValue)")) {
                    Invoke-CropItem $mediaFile -OutputFile $outputFile
                }
                $cropped.Add($mediaFile)
            }
            else {
                Write-Host '🚫 No crop value found' -ForegroundColor Red
                $skipped.Add($mediaFile)
            }
        }
    }
    end {
        Write-Host '✅ Done with all files' -ForegroundColor Green
        Write-Host "📂 Cropped $($cropped.Count) files" -ForegroundColor Green
        $skippedFiles = ($skipped | ForEach-Object { $_.Path }) -join '`n'
        Write-Host "📂 Skipped $($skipped.Count) files:" -ForegroundColor Magenta
        Write-Host "`t$($skippedFiles -join '`n`t')" -ForegroundColor Magenta

        return [PSCustomObject]@{
            MediaFiles = $mediaFiles
            Cropped    = $cropped
            Skipped    = $skipped
        }
    }
}

$prevScratchVer = $global:scratchVer
$scratchVer = 13
Write-Host "🔄 Scratch version: $prevScratchVer 🔒 $scratchVer ➡️ $($global:scratchVer) ✅" -ForegroundColor Cyan
