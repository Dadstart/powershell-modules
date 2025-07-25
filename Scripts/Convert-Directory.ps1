param(
    [string] $InputDirectory,
    [switch] $SkipConvert
)

@('Convert-MediaFile','Write-Message', 'Invoke-FFMpeg', 'Invoke-Process') | ForEach-Object {
    $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
    $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
}

Write-Message "📂 Converting directory: $InputDirectory" -Type Processing

$inputDir = Get-Path $InputDirectory -PathType Absolute
Write-Message "InputDir: $inputDir"
$outputDir = Get-Path @($inputDir, 'MP4') -PathType Absolute -Create Directory
Write-Message "OutputDir: $outputDir"

# $videoSettings = New-VideoEncodingSettings -Codec x264 -CRF 21 -Preset slow -CodecProfile high -Tune film
$videoSettings = New-VideoEncodingSettings -Codec x264 -Bitrate 5000 -Preset slow
$audioMapping0 = New-AudioTrackMapping -SourceIndex 0 -DestinationIndex 1 -CopyOriginal -Title 'DTS-HD'
$audioMapping1 = New-AudioTrackMapping -SourceIndex 1 -DestinationIndex 0 -DestinationCodec aac -DestinationChannels 6 -Title 'Surround 5.1'
Write-Message "Video settings: $($videoSettings.ToFfmpegArgs(1) -join ' ')"
Write-Message "Audio mapping 0: $($audioMapping0.ToFfmpegArgs() -join ' ')"
Write-Message "Audio mapping 1: $($audioMapping1.ToFfmpegArgs() -join ' ')"

$allFiles = Get-ChildItem $inputDir *.mkv
Write-Message "Converting $($allFiles.Count) files" -Type Processing
$allFiles | ForEach-Object {
    Write-Message "Processing: $($_.BaseName)" -Type Processing

    $outputFileName = (Get-Path $_ -PathType LeafBase) + '.mp4'
    $outputFile = Get-Path @($outputDir, $outputFileName) -PathType Absolute
    Write-Message "OutputFile: $outputFile"

    if (-not $SkipConvert) {
        Convert-MediaFile -InputFiles $_.FullName -OutputFile $outputFile -VideoSettings $videoSettings -AudioMappings @($audioMapping0, $audioMapping1)
    }
}

Write-Message '📂 Directory conversion completed' -Type Success
