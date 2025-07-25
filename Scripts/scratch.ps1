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
function Get-CropValue {
    [CmdletBinding()]
    param (
        [string]$inputFile
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
        Write-Host 'Detecting crop parameters...' -ForegroundColor White

        # Crop detection using FFmpeg (sample 20s from 2:00)
        $ffmpegArgs = @(
            '-ss', '00:02:00',
            '-t', '00:00:20',
            '-i', "`"$inputFile`"",
            '-vf', 'cropdetect',
            '-f', 'null'
        )
        # $cropDetect = ffmpeg @ffmpegArgs 2>&1
        Write-Message "Running FFmpeg with arguments: $($ffmpegArgs -join ' ')" -Type Info
        $ffmpegResult = Invoke-FFmpeg @ffmpegArgs
        Write-Message "FFmpeg result: `n$($ffmpegResult.Result | ConvertTo-Json)" -Type Info
        $cropDetect = $ffmpegResult.Output

        # Extract last crop value from output
        $cropMatches = $cropDetect | Select-String 'crop='

        if ($null -eq $cropMatches) {
            Write-Message 'No crop parameters detected in FFmpeg output' -Type Warning
            return $null
        }

        $lastCropMatch = $cropMatches | Select-Object -Last 1

        if ($null -eq $lastCropMatch) {
            Write-Message 'Failed to extract last crop match' -Type Warning
            return $null
        }

        $cropParam = $lastCropMatch.ToString()

        if ([string]::IsNullOrWhiteSpace($cropParam)) {
            Write-Message 'Crop parameter string is null or empty' -Type Warning
            return $null
        }

        $cropValue = $cropParam -replace '.*crop=', ''

        if ([string]::IsNullOrWhiteSpace($cropValue)) {
            Write-Message 'Extracted crop value is null or empty' -Type Warning
            return $null
        }

        Write-Message "Detected crop parameters: $cropValue" -Type Info

        return $cropValue
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
        # Apply crop and encode with x264
        $ffmpegArgs = @(
            '-i', "`"$($MediaFile.Path)`"",
            '-vf', "crop=$($MediaFile.CropValue)",
            '-c:v', 'libx264',
            '-preset', 'veryslow',
            '-crf', '17',
            '-c:a', 'copy',
            "`"$OutputFile`""
        )
        $ffmpegResult = Invoke-FFmpeg @ffmpegArgs
        # ffmpeg -i "$($MediaFile.Path)" -vf "crop=$($MediaFile.CropValue)" -c:v libx264 -preset veryslow -crf 17 -c:a copy "$OutputFile"
        if ($ffmpegResult.ExitCode -ne 0) {
            Write-Host "❌ Failed to crop $($MediaFile.Path)" -ForegroundColor Red
            Write-Host $ffmpegResult.Output -ForegroundColor Red
            return
        }

        Write-Host "Crop complete: $OutputFile" -ForegroundColor Green
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

$scratchVer = 8
Write-Host "🔄 Scratch version: $scratchVer ➡️ $($global:scratchVer) ✅" -ForegroundColor Cyan
