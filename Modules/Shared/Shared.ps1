# Shared functions module
# This file provides the actual module implementation for shared functions
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
# Get functions from Public directory
$functions = Get-ChildItem -Path $publicPath -File -Filter '*.ps1' | Select-Object -ExpandProperty BaseName
# Dot-source the shared functions
foreach ($function in $functions) {
    Write-Verbose "Dot-sourcing function: $function"
    $path = Join-Path $publicPath "$function.ps1"
    . $path
}
# Get classes from Classes directory
$classesPath = Join-Path -Path $PSScriptRoot -ChildPath 'Classes'
$classes = Get-ChildItem -Path $classesPath -File -Filter '*.ps1' | Select-Object -ExpandProperty BaseName
# Dot-source the shared classes
foreach ($class in $classes) {
    Write-Verbose "Dot-sourcing class: $class"
    $path = Join-Path $classesPath "$class.ps1"
    . $path
}
Export-ModuleMember -Function $functions -Variable $classes
