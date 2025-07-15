# Test script to demonstrate audio codec to extension mapping
# This script shows how Get-MediaExtension maps codec names to appropriate file extensions

Write-Host "=== Testing Audio Codec to Extension Mapping ===" -ForegroundColor Cyan

# Test various codec mappings
$testCodecs = @(
    'aac',
    'ac3', 
    'dts',
    'mp3',
    'flac',
    'wav',
    'ogg',
    'opus',
    'pcm_s16le',
    'eac3',
    'dts-hd',
    'truehd',
    'mlp',
    'alac',
    'amr',
    'vorbis',
    'mp2',
    'mp4a',
    'wma',
    'unknown_codec'
)

Write-Host "`nTesting audio codec to extension mapping:" -ForegroundColor Yellow
foreach ($codec in $testCodecs) {
    $extension = Get-MediaExtension -CodecType Audio -CodecName $codec
    Write-Host "  $codec -> $extension" -ForegroundColor White
}

Write-Host "`n=== Example Usage in Export-AudioStream ===" -ForegroundColor Cyan

# Simulate what happens in Export-AudioStream
$sampleStreams = @(
    @{ CodecName = 'aac'; Language = 'eng'; TypeIndex = 0 },
    @{ CodecName = 'ac3'; Language = 'eng'; TypeIndex = 1 },
    @{ CodecName = 'dts'; Language = 'spa'; TypeIndex = 0 },
    @{ CodecName = 'flac'; Language = 'fra'; TypeIndex = 0 }
)

$baseName = "sample_movie"
Write-Host "`nSample filename generation:" -ForegroundColor Yellow
foreach ($stream in $sampleStreams) {
    $extension = Get-MediaExtension -CodecType Audio -CodecName $stream.CodecName
    $filename = "$baseName.$($stream.Language).$($stream.TypeIndex)$extension"
    Write-Host "  $($stream.CodecName) -> $filename" -ForegroundColor White
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan 