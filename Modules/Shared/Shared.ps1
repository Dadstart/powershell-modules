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

$publicFunctions = @()
$publicClasses = @()

$publicFunctions += Get-ModuleType $ModuleRoot 'Public'
$publicClasses += Get-ModuleType $ModuleRoot 'Classes'
$privateFunctions += Get-ModuleType $ModuleRoot 'Private'


# Dot-source every .ps1 under Classes FIRST
Write-Host 'Loading shared classes' -ForegroundColor Cyan
foreach ($class in $publicClasses) {
    try {
        . $($class.FullName)
    }
    catch {
        Write-Host "✗ Failed to dot-source $($class.Name): $_" -ForegroundColor Red
    }
}

Write-Verbose 'Loading private functions'
foreach ($function in $privateFunctions) {
    Write-Verbose "Loading private function: $function"
    . (Join-Path $ModuleRoot -ChildPath 'Private', "$function.ps1")
    Write-Verbose "Loaded private function: $function"
}

Write-Verbose 'Loading public functions'
$publicFunctions = Get-ModuleType $ModuleRoot 'Public'
if ($publicFunctions) {
    $allPublicFunctions += $publicFunctions
    foreach ($function in $publicFunctions) {
        Write-Verbose "Loading public function: $function"
        . (Join-Path $ModuleRoot -ChildPath 'Public', "$function.ps1")
        Write-Verbose "Loaded shared function: $function"
    }
}

Write-Verbose 'Exporting functions'
