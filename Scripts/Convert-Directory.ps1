param(
    [string] $InputDirectory,
    [switch] $SkipConvert
)

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
    if (-not $SkipConvert) {
        Convert-MediaFile -InputFiles $_.FullName -OutputFile $outputFile -VideoSettings $videoSettings -AudioMappings @($audioMapping0, $audioMapping1)
    }
}
$progress.Stop(@{ Status = 'Directory conversion completed' })

Write-Progress -Activity "Converting $($allFiles.Count) files" -Id 1 -PercentComplete 100 -Status 'Complete' -Completed
Write-Host 'Complete' -ForegroundColor Green
