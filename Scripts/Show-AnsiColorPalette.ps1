function Show-AnsiColorPalette {
    $esc = [char]27

    function Write-ColorRow {
        param (
            [string]$label,
            [int[]]$codes
        )
        Write-Host "`n$label" -ForegroundColor White
        foreach ($code in $codes) {
            $ansi = "$esc[${code}m"
            $reset = "$esc[0m"
            Write-Host "$ansi Code $code $reset" -NoNewline
            Write-Host "`t" -NoNewline
        }
        Write-Host ''
    }

    Write-ColorRow 'Standard Foreground Colors (30–37):' @(30..37)
    Write-ColorRow 'Standard Background Colors (40–47):' @(40..47)
    Write-ColorRow 'Bright Foreground Colors (90–97):' @(90..97)
    Write-ColorRow 'Bright Background Colors (100–107):' @(100..107)
}
