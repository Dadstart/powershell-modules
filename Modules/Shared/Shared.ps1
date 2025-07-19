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

$allPublicFunctions = @()
$allPublicClasses = @()

# Shared 'Module' Loading
$classes = Get-ModuleType $ModuleRoot 'Classes'
if ($classes) {
    $allPublicClasses += $classes
    foreach ($class in $classes) {
        Write-Verbose "Loading module class: $class"
        . (Join-Path $ModuleRoot -ChildPath 'Classes', "$class.ps1")
        Write-Verbose "Loaded module class: $class"
    }
}

$publicFunctions = Get-ModuleType $ModuleRoot 'Public'
if ($publicFunctions) {
    $allPublicFunctions += $publicFunctions
    foreach ($function in $publicFunctions) {
        Write-Verbose "Loading public function: $function"
        . (Join-Path $ModuleRoot -ChildPath 'Public', "$function.ps1")
        Write-Verbose "Loaded shared function: $function"
    }
}

$privateFunctions = Get-ModuleType $ModuleRoot 'Private'
foreach ($function in $privateFunctions) {
    Write-Verbose "Loading private function: $function"
    . (Join-Path $ModuleRoot -ChildPath 'Private', "$function.ps1")
    Write-Verbose "Loaded private function: $function"
}

# Export all public functions
if ($allPublicFunctions) {
    Export-ModuleMember -Function $allPublicFunctions
}

# Export all public classes
if ($allPublicClasses) {
    Export-ModuleMember -Variable $allPublicClasses
}
