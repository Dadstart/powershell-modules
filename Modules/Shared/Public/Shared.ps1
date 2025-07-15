# Shared functions module
# This file provides IntelliSense support for shared functions

# Dot-source the shared functions
$SharedPath = $PSScriptRoot
. (Join-Path $SharedPath 'Get-Path.ps1')
. (Join-Path $SharedPath 'Write-Message.ps1')

# Export functions for IntelliSense (these won't be exported by individual modules)
Export-ModuleMember -Function Get-Path, Write-Message 