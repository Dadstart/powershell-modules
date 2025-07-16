# Test script for ANSI color support in Write-Message
# Import the module
Import-Module .\Modules\Shared\Public\Write-Message.ps1 -Force

Write-Host "=== ANSI Color Support Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Default behavior (auto-detect)
Write-Host "Test 1: Default behavior (auto-detect ANSI support)" -ForegroundColor Yellow
Write-Message "This is an Info message" -Type Info
Write-Message "This is a Success message" -Type Success
Write-Message "This is a Warning message" -Type Warning
Write-Message "This is an Error message" -Type Error
Write-Message "This is a Processing message" -Type Processing
Write-Host ""

# Test 2: Force ANSI
Write-Host "Test 2: Forcing ANSI escape codes" -ForegroundColor Yellow
Set-WriteMessageConfig -ForceAnsi
Write-Message "This is an Info message (ANSI forced)" -Type Info
Write-Message "This is a Success message (ANSI forced)" -Type Success
Write-Message "This is a Warning message (ANSI forced)" -Type Warning
Write-Message "This is an Error message (ANSI forced)" -Type Error
Write-Message "This is a Processing message (ANSI forced)" -Type Processing
Write-Host ""

# Test 3: Disable ANSI
Write-Host "Test 3: Disabling ANSI (PowerShell native colors)" -ForegroundColor Yellow
Set-WriteMessageConfig -DisableAnsi
Write-Message "This is an Info message (ANSI disabled)" -Type Info
Write-Message "This is a Success message (ANSI disabled)" -Type Success
Write-Message "This is a Warning message (ANSI disabled)" -Type Warning
Write-Message "This is an Error message (ANSI disabled)" -Type Error
Write-Message "This is a Processing message (ANSI disabled)" -Type Processing
Write-Host ""

# Test 4: Custom colors with Purple
Write-Host "Test 4: Custom colors including Purple" -ForegroundColor Yellow
Set-WriteMessageConfig -LevelColors @{
    'Info'       = 'Purple'
    'Success'    = 'Green'
    'Warning'    = 'Yellow'
    'Error'      = 'Red'
    'Processing' = 'Cyan'
    'Debug'      = 'Gray'
    'Verbose'    = 'Gray'
}
Write-Message "This Info message should be Purple" -Type Info
Write-Message "This Success message should be Green" -Type Success
Write-Host ""

# Test 5: Show current configuration
Write-Host "Test 5: Current configuration" -ForegroundColor Yellow
Get-WriteMessageConfig | Format-List
Write-Host ""

# Test 6: Reset to defaults
Write-Host "Test 6: Reset to defaults" -ForegroundColor Yellow
Set-WriteMessageConfig -Reset
Write-Message "This should be back to default colors" -Type Info
Write-Message "Configuration reset complete" -Type Success
Write-Host ""

Write-Host "=== Test Complete ===" -ForegroundColor Cyan 