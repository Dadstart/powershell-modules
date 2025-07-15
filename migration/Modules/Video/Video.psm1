# Video Processing Module
# Contains functions for video processing, conversion, and management

$requiredModule = 'VideoUtility'

# Check for required VideoUtility module
Write-Verbose 'Installed modules:'
Get-Module | ForEach-Object { Write-Verbose "`t$($_.Name); Path: $($_.Path)" }
if (-not (Get-Module $requiredModule)) {
    Write-Verbose "$requiredModule module not found"
    $errorMessage = "Required module '$requiredModule' is not installed. Please install it before importing this module."
    Write-Message $errorMessage -Type Error
    throw $errorMessage
}
Write-Verbose "$requiredModule module found"

# Import constants first
$constantsPath = Join-Path $PSScriptRoot "Private\Constants.ps1"
if (Test-Path $constantsPath) {
    Write-Verbose "Loading constants from: $constantsPath"
    . $constantsPath
}

# Import all private functions first
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' | Where-Object { $_.Name -ne "Constants.ps1" } | ForEach-Object {
    Write-Verbose "Importing private function: $($_.Name)"
    . $_.FullName
}

# Import and export all public functions
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' | ForEach-Object {
    Write-Verbose "Importing private function: $($_.Name)"
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
}

# Import and export all test functions
$testPath = Join-Path $PSScriptRoot 'Test'
if (Test-Path $testPath) {    
    Get-ChildItem -Path $testPath -Filter '*.ps1' | ForEach-Object {
        Write-Verbose "Importing test function: $($_.Name)"
        . $_.FullName
        Export-ModuleMember -Function $_.BaseName
    }
}
