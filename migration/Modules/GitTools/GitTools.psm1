
# Import all private functions first
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' | Where-Object { $_.Name -ne 'Constants.ps1' } | ForEach-Object {
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
