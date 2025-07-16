#Requires -Version 7.4

# Git Module Root Script
# This file serves as the entry point for the Git module

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Import shared functions
$sharedPublicPath = Join-Path $ModuleRoot '..\Shared\Public'
$sharedFunctions = Get-ChildItem -Path $sharedPublicPath -Filter '*.ps1' | Sort-Object Name

foreach ($function in $sharedFunctions) {
    . $function.FullName
}

# Export all loaded functions
$sharedFunctionNames = $sharedFunctions | ForEach-Object { $_.BaseName }

# Get classes from Classes directory
$sharedClassesPath = Join-Path $ModuleRoot '..\Shared\Classes'
$sharedClassNames = Get-ChildItem -Path $sharedClassesPath -File -Filter '*.ps1' | Select-Object -ExpandProperty BaseName

# Dot-source the shared classes
foreach ($class in $sharedClassNames) {
    Write-Verbose "Dot-sourcing class: $class"
    $path = Join-Path $sharedClassesPath "$class.ps1"
    . $path
}

Export-ModuleMember -Function $sharedFunctionNames -Variable $sharedClassNames

<#
# Dot-source shared functions directly with dependency order
$SharedPublicPath = Join-Path $ModuleRoot '..\Shared\Public'

# Define load order for functions with dependencies
$sharedFunctionOrder = @(
    'Get-WriteMessageConfig',  # Load first - no dependencies
    'Set-WriteMessageConfig',  # Depends on Get-WriteMessageConfig
    'Write-Message',           # Depends on Get-WriteMessageConfig
    'Get-String',              # No dependencies
    'Get-Path',                # No dependencies
    'Get-EnvironmentInfo',     # No dependencies
    'Invoke-WithErrorHandling', # No dependencies
    'New-ProcessingDirectory', # No dependencies
    'Set-PreferenceInheritance', # No dependencies
    'Start-ProgressActivity'   # No dependencies
)

# Load functions in dependency order
foreach ($function in $sharedFunctionOrder) {
    $functionPath = Join-Path $SharedPublicPath "$function.ps1"
    if (Test-Path $functionPath) {
        Write-Verbose "Loading shared function: $function"
        . $functionPath
    } else {
        Write-Warning "Shared function file not found: $functionPath"
    }
}

# Load any remaining functions that weren't in the ordered list
$remainingFunctions = Get-ChildItem -Path $SharedPublicPath -Filter '*.ps1' | 
    Where-Object { $_.BaseName -notin $sharedFunctionOrder } |
    Select-Object -ExpandProperty BaseName

foreach ($function in $remainingFunctions) {
    $functionPath = Join-Path $SharedPublicPath "$function.ps1"
    Write-Verbose "Loading remaining shared function: $function"
    . $functionPath
}
#>

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