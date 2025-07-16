# Shared functions module
# This file provides the actual module implementation for shared functions

$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$functions = Get-ChildItem -Path $publicPath -File -Filter '*.ps1' | Select-Object -ExpandProperty BaseName

# Dot-source the shared functions
foreach ($function in $functions) {
    Write-Verbose "Dot-sourcing function: $function"
    $path = Join-Path $publicPath "$function.ps1"
    . $path
}

Export-ModuleMember -Function $functions