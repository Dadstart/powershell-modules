<<<<<<< HEAD
=======
[CmdletBinding()]
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
param(
    [string] $InputDirectory,
    [switch] $SkipConvert
)

<<<<<<< HEAD
$inputDir = Get-Path $InputDirectory -PathType Absolute
Write-Host "InputDir: $inputDir"
$outputDir = Get-Path @($inputDir, 'MP4') -PathType Absolute -Create Directory
Write-Host "OutputDir: $outputDir"

$progress = Start-ProgressActivity -Activity "Converting $($allFiles.Count) files" -Id 1 -Status 'Processing files from directory...' -TotalItems $allFiles.Count

$videoSettings = New-VideoEncodingSettings -Codec x264 -CRF 21 -Preset slow -CodecProfile high -Tune film
$audioMapping0 = New-AudioTrackMapping -SourceIndex 0 -DestinationIndex 1 -CopyOriginal -Title 'DTS-HD'
$audioMapping1 = New-AudioTrackMapping -SourceIndex 1 -DestinationIndex 0 -DestinationCodec aac -DestinationChannels 6 -Title 'Surround 5.1'


$allFiles = Get-ChildItem $inputDir *.mkv
$i = 0
$allFiles | ForEach-Object {
    $i++
    $progress.Update(@{
            CurrentItem = $i
            Status = "Processing: $($_.BaseName)"
        })

    $outputFile = Join-Path $outputDir ("$($_.BaseName).mp4")
    Write-Progress -Activity "Converting $($allFiles.Count) files" -Id 1 -Status "$i of $($allFiles.Count)" -PercentComplete ([double]($i - 1) / [double]$allFiles.Count)
    Write-Host $outputFile -ForegroundColor Cyan
=======
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

>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
    if (-not $SkipConvert) {
        Convert-MediaFile -InputFiles $_.FullName -OutputFile $outputFile -VideoSettings $videoSettings -AudioMappings @($audioMapping0, $audioMapping1)
    }
}
<<<<<<< HEAD
$progress.Stop(@{ Status = 'Directory conversion completed' })

Write-Progress -Activity "Converting $($allFiles.Count) files" -Id 1 -PercentComplete 100 -Status 'Complete' -Completed
Write-Host 'Complete' -ForegroundColor Green
=======

Write-Message '📂 Directory conversion completed' -Type Success
>>>>>>> 1a97b2f (Add MediaFile/MediaFormat/MediaStream/MediChapter. Add Convert-MediaFile to perform encoding.)
