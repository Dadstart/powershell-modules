#Requires -Version 7.4

# Rip Module Root Script
# This file serves as the entry point for the Rip module

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Dot-source shared functions
$SharedPath = Join-Path $ModuleRoot '..\Shared'
. (Join-Path -Path $SharedPath -ChildPath 'Shared.psm1')

# Load private functions first (these won't be exported)
$PrivatePath = Join-Path $ModuleRoot 'Private'
if (Test-Path $PrivatePath)
{
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Load public functions (these will be exported)
$PublicPath = Join-Path $ModuleRoot 'Public'
if (Test-Path $PublicPath)
{
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Load classes
$ClassesPath = Join-Path $ModuleRoot 'Classes'
if (Test-Path $ClassesPath)
{
    Get-ChildItem -Path $ClassesPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Export public functions
# Get all functions that were loaded from the Public directory
$PublicFunctions = @()
if (Test-Path $PublicPath)
{
    $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        $FunctionName = $_.BaseName
        # Check if the function actually exists after being loaded
        if (Get-Command -Name $FunctionName -ErrorAction SilentlyContinue)
        {
            $FunctionName
        }
    } | Where-Object { $_ -ne $null }
}

Export-ModuleMember -Function $PublicFunctions 