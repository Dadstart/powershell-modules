#Requires -Version 7.4

# Rip Module Root Script
# This file serves as the entry point for the Rip module

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Dot-source shared functions
$SharedPath = Join-Path $ModuleRoot '..\Shared\Public'
. (Join-Path $SharedPath 'Get-Path.ps1')
. (Join-Path $SharedPath 'Write-Message.ps1')

# Load private functions first (these won't be exported)
$PrivatePath = Join-Path $ModuleRoot 'Private'
if (Test-Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Load public functions (these will be exported)
$PublicPath = Join-Path $ModuleRoot 'Public'
if (Test-Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Export public functions
$PublicFunctions = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
    $FunctionName = $_.BaseName
    if (Get-Command -Name $FunctionName -ErrorAction SilentlyContinue) {
        $FunctionName
    }
}

Export-ModuleMember -Function $PublicFunctions 