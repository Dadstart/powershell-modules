#Requires -Version 7.4

# Rip Module Root Script
# This file serves as the entry point for the Rip module

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Import shared functions
$SharedPublicPath = Join-Path $ModuleRoot '..\Shared\Public'
$sharedFunctions = Get-ChildItem -Path $SharedPublicPath -Filter '*.ps1' | Sort-Object Name

foreach ($function in $sharedFunctions) {
    . $function.FullName
}

# Export all loaded functions
$functionNames = $sharedFunctions | ForEach-Object { $_.BaseName }
Export-ModuleMember -Function $functionNames

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

# Add WriteMessageConfig functions to exports for consumer access
# These functions should be available from the Shared module dot-sourcing
$SharedFunctions = @('Set-WriteMessageConfig', 'Get-WriteMessageConfig', 'Write-Message')
foreach ($function in $SharedFunctions) {
    if (Get-Command -Name $function -ErrorAction SilentlyContinue) {
        $PublicFunctions += $function
        Write-Verbose "Added Shared function to exports: $function"
    } else {
        Write-Warning "Shared function not found: $function"
    }
}

Export-ModuleMember -Function $PublicFunctions 