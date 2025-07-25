if ($false) {

    Get-ChildItem *.mkv | ForEach-Object { Get-MediaFile $_ } | Set-Variable files
    foreach ($file in $files) {
        $files[0].Streams[0].Raw.width, $files[0].Streams[0].Raw.height
    }

    $files | Where-Object { $_.Streams[0].Raw.width -eq 1080 }
}


# Define input/output

function Get-CropValue {
    param (
        [string]$inputFile
    )

    Write-Host 'Detecting crop parameters...' -ForegroundColor White

    # Crop detection using FFmpeg (sample 20s from 2:00)
    $cropDetect = ffmpeg -ss 00:02:00 -t 00:00:20 -i $inputFile -vf cropdetect -f null - 2>&1

    # Extract last crop value from output
    $cropMatches = $cropDetect | Select-String 'crop='

    if ($null -eq $cropMatches) {
        Write-Message -Type Warning -Message 'No crop parameters detected in FFmpeg output'
        return $null
    }

    $lastCropMatch = $cropMatches | Select-Object -Last 1

    if ($null -eq $lastCropMatch) {
        Write-Message -Type Warning -Message 'Failed to extract last crop match'
        return $null
    }

    $cropParam = $lastCropMatch.ToString()

    if ([string]::IsNullOrWhiteSpace($cropParam)) {
        Write-Message -Type Warning -Message 'Crop parameter string is null or empty'
        return $null
    }

    $cropValue = $cropParam -replace '.*crop=', ''

    if ([string]::IsNullOrWhiteSpace($cropValue)) {
        Write-Message -Type Warning -Message 'Extracted crop value is null or empty'
        return $null
    }

    Write-Host "Detected crop parameters: $cropValue" -ForegroundColor White

    return $cropValue
}

function Add-CropValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [psobject]$MediaFile
    )

    process {
        $cropValue = Get-CropValue -inputFile $MediaFile.Path
        Add-Member -InputObject $MediaFile -MemberType NoteProperty -Name 'CropValue' -Value $cropValue
    }
}


function Invoke-CropItem {
    param (
        [CmdletBinding()]
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [psobject]$MediaFile,
        [Parameter(Mandatory)]
        [string]$OutputFile
    )
    process {
        # Apply crop and encode with x264
        if ($false) {
            ffmpeg -i "$MediaFile.Path" -vf "crop=$($MediaFile.CropValue)" -c:v libx264 -preset veryslow -crf 17 -c:a copy "$OutputFile"
        }

        Write-Host "Crop complete: $OutputFile" -ForegroundColor Green
    }
}

function ConvertTo-Cropped {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$InputFolder
    )
    begin {
        $mediaFiles = Get-ChildItem $InputFolder -Filter *.mkv | ForEach-Object { Get-MediaFile $_ }
        Write-Host "📽️ Found $($mediaFiles.Count) files" -ForegroundColor Cyan
    }
    process {
        foreach ($mediaFile in $mediaFiles) {
            $inputFile = $mediaFile.Path
            $outputFile = [System.IO.Path]::ChangeExtension($inputFile, '_cropped.mkv')
            Write-Host "📝 Processing $($inputFile) -> $($outputFile)" -ForegroundColor Cyan
            Add-CropValues $mediaFile
            Write-Host "🎯 Crop value: $($mediaFile.CropValue)" -ForegroundColor Gray
            Invoke-CropItem $mediaFile -OutputFile $outputFile
        }
    }
    end {
        Write-Host '✅ Done with all files' -ForegroundColor Green
    }
}
