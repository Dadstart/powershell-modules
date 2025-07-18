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
        [string]$TypeName,
        [Parameter()]
        [string]$Property = 'BaseName'
    )

    $typesPath = Join-Path $RootPath $TypeName
    if (Test-Path $typesPath) {
        $types = Get-ChildItem -Path $typesPath -Filter '*.ps1' |
            Sort-Object $Property # |
        #   Select-Object -ExpandProperty $Property
        return $types
    }
    else {
        return @()
    }
}



$publicFunctions = @()
$publicClasses = @()

# Shared loading
$sharedRoot = Join-Path $ModuleRoot '..\Shared'
$publicClasses += Get-ModuleType $sharedRoot 'Classes'
$publicFunctions += Get-ModuleType $sharedRoot 'Public'

# Module Loading
$publicClasses += Get-ModuleType $ModuleRoot 'Classes'
$publicFunctions += Get-ModuleType $ModuleRoot 'Public'
$privateFunctions = Get-ModuleType $ModuleRoot 'Private'

Write-Host 'Loading private functions' -ForegroundColor Cyan
foreach ($function in $privateFunctions) {
    . $($function.FullName)
}

Write-Host 'Loading public functions' -ForegroundColor Cyan
foreach ($function in $publicFunctions) {
    . $($function.FullName)
}

# 2) Dot-source every .ps1 under Classes
Write-Host 'Loading public classes' -ForegroundColor Cyan
foreach ($class in $publicClasses) {
    try {
        . $($class.FullName)
    }
    catch {
        Write-Host "✗ Failed to dot-source $($class.Name): $_" -ForegroundColor Red
    }
}

Write-Host 'Exporting functions' -ForegroundColor Cyan
Export-ModuleMember -Function ($publicFunctions | ForEach-Object { $_.BaseName })
