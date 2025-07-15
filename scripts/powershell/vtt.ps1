param(
[string]$root
)

Get-ChildItem -Path $root -Recurse -Filter *.srt | ForEach-Object {
    $srtPath = $_.FullName
    $vttPath = [System.IO.Path]::ChangeExtension($srtPath, ".vtt")

    if (-not (Test-Path $vttPath)) {
        Write-Host "Converting: $srtPath → $vttPath"
        ffmpeg -hide_banner -loglevel error -y -i $srtPath $vttPath
    } else {
        Write-Host "Skipping (already exists): $vttPath"
    }
}
