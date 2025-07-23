param (
    [Parameter(Mandatory, Position = 1)]
    [string]$Path,
    [Parameter(Mandatory, Position = 2)]
    [string]$Extension,
    [Parameter()]
    [string]$Exclude
)
Get-ChildItem -Path $Path -Recurse -Filter "*$Extension" -File -Exclude $Exclude | ForEach-Object {
    $FilePath = $_.FullName
    $CleanedLines = Get-Content $FilePath | ForEach-Object {
        if ($_ -match '^\s*$') {
            ''  # Return empty string for lines that are only whitespace
        } else {
            $_.TrimEnd()  # Remove trailing whitespace from non-empty lines
        }
    }
    $CleanedLines | Set-Content $FilePath
    Write-Host "Cleaned: $FilePath"
}
