#Requires -Version 7.4
# GitTools Module Root Script
# This file serves as the entry point for the GitTools module

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

# Dot-source every .ps1 under Classes FIRST
Write-Verbose 'Loading public classes'
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
    . $($function.FullName)
}

Write-Verbose 'Loading public functions'
foreach ($function in $publicFunctions) {
    . $($function.FullName)
}

Write-Verbose 'Exporting functions'
Export-ModuleMember -Function ($publicFunctions | ForEach-Object { $_.BaseName })
