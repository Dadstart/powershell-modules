param (
    [Parameter(Mandatory, Position = 1)]
    [string]$Path,
    [Parameter(Mandatory, Position = 2)]
    [string]$Extension
)
Get-ChildItem -Path $Path -Recurse -Filter "*$Extension" -File | ForEach-Object {
    $FilePath = $_.FullName
    $CleanedLines = Get-Content $FilePath | Where-Object { $_ -notmatch '^\s*$' }
    $CleanedLines | Set-Content $FilePath
    Write-Host "Cleaned: $FilePath"
}
