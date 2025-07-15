# Test script to demonstrate subtitle codec to extension mapping
# This script shows how Get-SubtitleExtension maps codec names to appropriate file extensions

Write-Host "=== Testing Subtitle Codec to Extension Mapping ===" -ForegroundColor Cyan

# Test various codec mappings
$testCodecs = @(
    'subrip',
    'hdmv_pgs_subtitle', 
    'dvd_subtitle',
    'ass',
    'ssa',
    'mov_text',
    'webvtt',
    'eia_608',
    'hdmv_text_subtitle',
    'xsub',
    'microdvd',
    'sami',
    'realtext',
    'pjs',
    'mpl2',
    'stl',
    'scc',
    'ttml',
    'dfxp',
    'unknown_codec'
)

Write-Host "`nTesting codec to extension mapping:" -ForegroundColor Yellow
foreach ($codec in $testCodecs) {
    $extension = Get-SubtitleExtension -CodecName $codec
    Write-Host "  $codec -> $extension" -ForegroundColor White
}

Write-Host "`n=== Example Usage in Export-SubtitleStream ===" -ForegroundColor Cyan

# Simulate what happens in Export-SubtitleStream
$sampleStreams = @(
    @{ CodecName = 'subrip'; Language = 'eng'; TypeIndex = 0 },
    @{ CodecName = 'hdmv_pgs_subtitle'; Language = 'eng'; TypeIndex = 1 },
    @{ CodecName = 'ass'; Language = 'spa'; TypeIndex = 0 },
    @{ CodecName = 'webvtt'; Language = 'fra'; TypeIndex = 0 }
)

$baseName = "sample_movie"
Write-Host "`nSample filename generation:" -ForegroundColor Yellow
foreach ($stream in $sampleStreams) {
    $extension = Get-SubtitleExtension -CodecName $stream.CodecName
    $filename = "$baseName.$($stream.Language).$($stream.TypeIndex)$extension"
    Write-Host "  $($stream.CodecName) -> $filename" -ForegroundColor White
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan 