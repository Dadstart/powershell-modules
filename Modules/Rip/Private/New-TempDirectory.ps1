function New-TempDirectory {
    <#
    .SYNOPSIS
        Creates a new temporary directory with a random name.
    #>
    [CmdletBinding()]
    param(
        [string]$Root
    )
    if (-not $Root) {
        $Root = [System.IO.Path]::GetTempPath()
    }
    $shortId = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
    $tempDir = Get-Path -Path $Root, "video_$shortId" -PathType Absolute -Create Directory
    return $tempDir
}
