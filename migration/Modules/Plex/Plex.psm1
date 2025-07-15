# Import the PlexCredential class first
. (Join-Path $PSScriptRoot 'Public\PlexCredential.ps1')

# Import all private functions
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' | Where-Object { $_.Name -ne "Constants.ps1" } | ForEach-Object {
    Write-Message "Importing private function: $($_.Name)" -Type Verbose
    . $_.FullName
}

# Import and export all public functions
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' | Where-Object { $_.Name -ne "PlexCredential.ps1" } | ForEach-Object {
    Write-Message "Importing public function: $($_.Name)" -Type Verbose
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
} 