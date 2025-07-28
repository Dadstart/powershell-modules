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
$privateFunctions = @()

$publicFunctions += Get-ModuleType $ModuleRoot 'Public'
Write-Verbose "Public Functions: $($publicFunctions -join ', ')"
$publicClasses += Get-ModuleType $ModuleRoot 'Classes'
Write-Verbose "Public Classes: $($publicClasses -join ', ')"
$privateFunctions += Get-ModuleType $ModuleRoot 'Private'
Write-Verbose "Private Functions: $($privateFunctions -join ', ')"


# Dot-source every .ps1 under Classes FIRST
Write-Verbose 'Loading shared classes'
foreach ($class in $publicClasses) {
    Write-Verbose "Class: $($class)"
    Write-Verbose "Loading public class: $($class)"
    try {
        $classPath = Join-Path $ModuleRoot -ChildPath 'Classes' | Join-Path -ChildPath "$class.ps1"
        . $classPath
    }
    catch {
        Write-Error "✗ Failed to dot-source $($class): $_"
        Write-Error "⚠️ $err"
        throw "⚠️ $err"
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
