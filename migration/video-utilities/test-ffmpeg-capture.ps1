# Test script to verify Invoke-FFMpeg properly captures output
# This should NOT show any ffmpeg output to the console

# Import the module
Import-Module .\PowerShell\VideoUtility\VideoUtility.psm1 -Force

Write-Host "Testing Invoke-FFMpeg output capture..." -ForegroundColor Green
Write-Host "If this works correctly, you should NOT see any ffmpeg output below:" -ForegroundColor Yellow
Write-Host ""

# Test 1: Version command (should have output)
Write-Host "Test 1: ffmpeg -version" -ForegroundColor Cyan
$result1 = Invoke-FFMpeg @('-version')
Write-Host "Exit Code: $($result1.ExitCode)" -ForegroundColor White
Write-Host "Output Length: $($result1.Output.Length)" -ForegroundColor White
Write-Host "Error Length: $($result1.Error.Length)" -ForegroundColor White
Write-Host "First 100 chars of output: $($result1.Output.Substring(0, [Math]::Min(100, $result1.Output.Length)))" -ForegroundColor Gray
Write-Host ""

# Test 2: Invalid command (should have error)
Write-Host "Test 2: ffmpeg -invalid-option" -ForegroundColor Cyan
$result2 = Invoke-FFMpeg @('-invalid-option')
Write-Host "Exit Code: $($result2.ExitCode)" -ForegroundColor White
Write-Host "Output Length: $($result2.Output.Length)" -ForegroundColor White
Write-Host "Error Length: $($result2.Error.Length)" -ForegroundColor White
Write-Host "First 100 chars of error: $($result2.Error.Substring(0, [Math]::Min(100, $result2.Error.Length)))" -ForegroundColor Gray
Write-Host ""

Write-Host "Test completed!" -ForegroundColor Green 