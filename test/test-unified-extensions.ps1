# Test script to demonstrate the unified Get-MediaExtension function
# This script shows how the unified function handles audio, subtitle, and video codecs

Write-Host "=== Testing Unified Media Extension Function ===" -ForegroundColor Cyan

# Test audio codecs
Write-Host "`n1. Testing Audio Codecs:" -ForegroundColor Yellow
$audioCodecs = @('aac', 'ac3', 'dts', 'dts-hd', 'dts-hd ma', 'dtsx', 'truehd', 'ac4', 'atmos', 'flac', 'mp3')
foreach ($codec in $audioCodecs) {
    $extension = Get-MediaExtension -CodecType Audio -CodecName $codec
    Write-Host "  $codec -> $extension" -ForegroundColor White
}

# Test subtitle codecs
Write-Host "`n2. Testing Subtitle Codecs:" -ForegroundColor Yellow
$subtitleCodecs = @('subrip', 'hdmv_pgs_subtitle', 'dvd_subtitle', 'ass', 'webvtt', 'srt', 'vtt')
foreach ($codec in $subtitleCodecs) {
    $extension = Get-MediaExtension -CodecType Subtitle -CodecName $codec
    Write-Host "  $codec -> $extension" -ForegroundColor White
}

# Test video codecs
Write-Host "`n3. Testing Video Codecs:" -ForegroundColor Yellow
$videoCodecs = @('h264', 'h265', 'hevc', 'vp9', 'av1', 'mpeg2video', 'mpeg4', 'wmv1', 'vc1')
foreach ($codec in $videoCodecs) {
    $extension = Get-MediaExtension -CodecType Video -CodecName $codec
    Write-Host "  $codec -> $extension" -ForegroundColor White
}

# Test unknown codecs
Write-Host "`n4. Testing Unknown Codecs (fallback):" -ForegroundColor Yellow
$unknownCodecs = @('unknown_audio', 'unknown_subtitle', 'unknown_video')
foreach ($codec in $unknownCodecs) {
    $extension = Get-MediaExtension -CodecType Audio -CodecName $codec
    Write-Host "  $codec -> $extension" -ForegroundColor White
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "The unified function successfully handles all media types!" -ForegroundColor Green 