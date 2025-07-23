cls; C:\modules\quick-install.ps1 -Quiet -Force
cd C:\temp\06

$file = Get-MediaFile -Path .\s06e01.raw.mkv

Write-Host '------------------------------------------------------------------------------------------------' -ForegroundColor Green
Write-Host "File:`n$($file)" -ForegroundColor Green
Write-Host "Format:`n$($file.Format)" -ForegroundColor Cyan
Write-Host "Chapters:`n$($file.Chapters)" -ForegroundColor Cyan
Write-Host "Streams:`n$($file.Streams)" -ForegroundColor Cyan
Write-Host '------------------------------------------------------------------------------------------------' -ForegroundColor Green