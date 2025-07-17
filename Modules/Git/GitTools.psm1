#Requires -Version 7.4

# Rip Module Root Script
# This file serves as the entry point for the Rip module

# Get the module root directory
$ModuleRoot = $PSScriptRoot

function Get-ModuleType {
    param(
        [Parameter(Mandatory, Position = 1)]
        [string]$RootPath,
        [Parameter(Mandatory, Position = 2)]
        [string]$TypeName
    )

    $typesPath = Join-Path $RootPath $TypeName
    if (Test-Path $typesPath) {
        $types = Get-ChildItem -Path $typesPath -Filter '*.ps1' |
            Sort-Object BaseName |
            Select-Object -ExpandProperty BaseName
        return $types
    }
    else {
        return @()
    }
}

# Shared loading
$sharedRoot = Join-Path $ModuleRoot '..\Shared'
$classes = Get-ModuleType $sharedRoot 'Classes'
if ($classes) {
    foreach ($class in $classes) {
        Write-Verbose "Loading shared class: $class"
        . (Join-Path $sharedRoot 'Classes' "$class.ps1")
        Write-Verbose "Loaded shared class: $class"
    }
    Export-ModuleMember -Variable $classes
}

$publicFunctions = Get-ModuleType $sharedRoot 'Public'
if ($publicFunctions) {
    foreach ($function in $publicFunctions) {
        Write-Verbose "Loading public shared function: $function"
        . (Join-Path $sharedRoot 'Public' "$function.ps1")
        Write-Verbose "Loaded public shared function: $function"
    }
    Export-ModuleMember -Function $publicFunctions
}

# Module Loading
$classes = Get-ModuleType $ModuleRoot 'Classes'
if ($classes) {
    foreach ($class in $classes) {
        Write-Verbose "Loading module class: $class"
        . (Join-Path $ModuleRoot 'Classes' "$class.ps1")
        Write-Verbose "Loaded module class: $class"
    }
    Export-ModuleMember -Variable $classes
}

$publicFunctions = Get-ModuleType $ModuleRoot 'Public'
if ($publicFunctions) {
    foreach ($function in $publicFunctions) {
        Write-Verbose "Loading public function: $function"
        . (Join-Path $ModuleRoot 'Public' "$function.ps1")
        Write-Verbose "Loaded shared function: $function"
    }
    Export-ModuleMember -Function $publicFunctions
}

$privateFunctions = Get-ModuleType $ModuleRoot 'Private'
foreach ($function in $privateFunctions) {
    Write-Verbose "Loading private function: $function"
    . (Join-Path $ModuleRoot 'Private' "$function.ps1")
    Write-Verbose "Loaded private function: $function"
}
