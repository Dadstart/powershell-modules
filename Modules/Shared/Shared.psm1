# Shared functions module
# This file provides the actual module implementation for shared functions

$sharedScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'Shared.ps1'
. $sharedScriptPath

# The functions are exported via the Shared.ps1 file
# The manifest (Shared.psd1) provides metadata but the actual exports happen in Shared.ps1
