# Test script to demonstrate the new Get-AudioStream and Export-AudioStream functions
# This script shows how to discover and export audio streams from video files

Write-Host "=== Testing Audio Stream Functions ===" -ForegroundColor Cyan

# Test 1: Get audio streams without export
Write-Host "`n1. Testing Get-AudioStream (discovery only):" -ForegroundColor Yellow
Get-AudioStream -Source "test.mkv" -Language eng -Verbose

# Test 2: Get audio streams and export them
Write-Host "`n2. Testing Get-AudioStream with Export-AudioStream:" -ForegroundColor Yellow
Get-AudioStream -Source "test.mkv" -Language eng | Export-AudioStream -OutputDirectory ".\test-audio-output" -Verbose

# Test 3: Get specific codec and export with format conversion
Write-Host "`n3. Testing codec-specific export with format conversion:" -ForegroundColor Yellow
Get-AudioStream -Source "test.mkv" -CodecName aac | Export-AudioStream -OutputFormat mp3 -OutputDirectory ".\test-audio-converted" -Verbose

# Test 4: Get all audio streams and export with force
Write-Host "`n4. Testing export with force flag:" -ForegroundColor Yellow
Get-AudioStream -Source "test.mkv" | Export-AudioStream -OutputDirectory ".\test-audio-all" -Force -Verbose

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Note: If test.mkv doesn't exist, you'll see appropriate error messages." -ForegroundColor Gray
Write-Host "The audio functions work similarly to the subtitle functions but for audio streams!" -ForegroundColor Green 