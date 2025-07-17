#Requires -Version 7.4

# Media Module Root Script
# This file serves as the entry point for the Media module

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# **Shared loading**
$sharedRoot = Join-Path $ModuleRoot '..\Shared'
$classes = Get-ChildItem -Path (Join-Path $sharedRoot 'Classes') -Filter '*.ps1' |
    Sort-Object BaseName |
    Select-Object -ExpandProperty BaseName
foreach ($class in $classes) {
    Write-Verbose "Loading shared class: $class"
    . (Join-Path $sharedRoot 'Classes' "$class.ps1")
    Write-Verbose "Loaded shared class: $class"
}
$publicFunctions = Get-ChildItem -Path (Join-Path $sharedRoot 'Public') -Filter '*.ps1' |
    Sort-Object BaseName |
    Select-Object -ExpandProperty BaseName
foreach ($function in $publicFunctions) {
    Write-Verbose "Loading shared function: $function"
    . (Join-Path $sharedRoot 'Public' "$function.ps1")
    Write-Verbose "Loaded shared function: $function"
}

Export-ModuleMember -Function $publicFunctions -Variable $classes

# **Module Loading**
$classes = Get-ChildItem -Path (Join-Path $ModuleRoot 'Classes') -Filter '*.ps1' |
    Sort-Object BaseName |
    Select-Object -ExpandProperty BaseName
foreach ($class in $classes) {
    Write-Verbose "Loading class: $class"
    . (Join-Path $ModuleRoot 'Classes' "$class.ps1")
    Write-Verbose "Loaded class: $class"
}
$privateFunctions = Get-ChildItem -Path (Join-Path $ModuleRoot 'Private') -Filter '*.ps1' |
    Sort-Object BaseName |
    Select-Object -ExpandProperty BaseName
foreach ($function in $privateFunctions) {
    Write-Verbose "Loading private function: $function"
    . (Join-Path $ModuleRoot 'Private' "$function.ps1")
    Write-Verbose "Loaded private function: $function"
}
$publicFunctions = Get-ChildItem -Path (Join-Path $ModuleRoot 'Public') -Filter '*.ps1' |
    Sort-Object BaseName |
    Select-Object -ExpandProperty BaseName
foreach ($function in $publicFunctions) {
    Write-Verbose "Loading public function: $function"
    . (Join-Path $ModuleRoot 'Public' "$function.ps1")
    Write-Verbose "Loaded public function: $function"
}

Export-ModuleMember -Function $publicFunctions -Variable $classes
