# Define enums for parameter validation
enum InstallScope {
    CurrentUser
    AllUsers
}

enum UninstallScope {
    CurrentUser
    AllUsers
    All
}

enum ReinstallScope {
    CurrentUser
    AllUsers
    All
}

enum VerbosityLevel {
    Silent
    Error
    Warning
    Info
    Success
    All
}

function Write-InstallationMessage {
    <#
    .SYNOPSIS
        Writes installation-related messages with verbosity control.

    .PARAMETER Message
        The message to display.

    .PARAMETER Type
        The type of message (Info, Success, Warning, Error).

    .PARAMETER VerbosityLevel
        The current verbosity level setting.

    .PARAMETER ScriptName
        The name of the calling script for timestamp formatting.
    #>
    param(
        [string]$Message,
        [string]$Type = 'Info',
        [VerbosityLevel]$VerbosityLevel = [VerbosityLevel]::All
    )

    # Check if message should be displayed based on verbosity level
    $shouldDisplay = switch ($VerbosityLevel) {
        'Silent' { $Type -eq 'Error' }
        'Error' { $Type -in @('Error') }
        'Warning' { $Type -in @('Error', 'Warning') }
        'Info' { $Type -in @('Error', 'Warning', 'Info') }
        'Success' { $Type -in @('Error', 'Warning', 'Info', 'Success') }
        'All' { $true }
        default { $true }
    }

    if (-not $shouldDisplay) {
        return
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    switch ($Type) {
        'Info' { Write-Information "[$timestamp] INFO: $Message" }
        'Success' { Write-Information "[$timestamp] SUCCESS: $Message" }
        'Warning' { Write-Warning "[$timestamp] WARNING: $Message" }
        'Error' { Write-Error "[$timestamp] ERROR: $Message" }
    }
}

function Test-Administrator {
    <#
    .SYNOPSIS
        Tests if the current session is running with administrative privileges.
    #>
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ModuleInstallPath {
    <#
    .SYNOPSIS
        Gets the module installation path based on scope and PowerShell edition.
    #>
    param(
        [string]$Scope
    )

    if ($Scope -eq 'AllUsers') {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            return "$env:ProgramFiles\PowerShell\Modules"
        }
        else {
            return "$env:ProgramFiles\WindowsPowerShell\Modules"
        }
    }
    else {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            return "$env:USERPROFILE\Documents\PowerShell\Modules"
        }
        else {
            return "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        }
    }
}

function Get-ModulePath {
    <#
    .SYNOPSIS
        Gets all possible module paths for VideoFunctions based on scope.
    #>
    param(
        [string]$Scope
    )

    $paths = @()

    # Current User paths
    if ($Scope -in @('CurrentUser', 'All')) {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            $paths += "$env:USERPROFILE\Documents\PowerShell\Modules\VideoFunctions"
        }
        else {
            $paths += "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\VideoFunctions"
        }
    }

    # All Users paths
    if ($Scope -in @('AllUsers', 'All')) {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            $paths += "$env:ProgramFiles\PowerShell\Modules\VideoFunctions"
        }
        else {
            $paths += "$env:ProgramFiles\WindowsPowerShell\Modules\VideoFunctions"
        }
    }

    return $paths
}

function Test-ModuleStructure {
    <#
    .SYNOPSIS
        Tests if the current directory contains a valid VideoFunctions module structure.
    #>
    param(
        [VerbosityLevel]$VerbosityLevel = [VerbosityLevel]::All
    )

    $requiredFiles = @(
        'VideoFunctions.psd1',
        'VideoFunctions.psm1'
    )

    $requiredDirectories = @(
        'Public',
        'Private'
    )

    # Check for required files
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-InstallationMessage -Message "Required file '$file' not found in current directory." -Type 'Error' -VerbosityLevel $VerbosityLevel
            return $false
        }
    }

    # Check for required directories
    foreach ($dir in $requiredDirectories) {
        if (-not (Test-Path $dir)) {
            Write-InstallationMessage -Message "Required directory '$dir' not found in current directory." -Type 'Error' -VerbosityLevel $VerbosityLevel
            return $false
        }
    }

    # Check for at least one function file in Public directory
    $publicFunctions = Get-ChildItem -Path 'Public' -Filter '*.ps1' -ErrorAction SilentlyContinue
    if ($publicFunctions.Count -eq 0) {
        Write-InstallationMessage -Message "No function files found in Public directory." -Type 'Error' -VerbosityLevel $VerbosityLevel
        return $false
    }

    return $true
}

function Get-ModuleVersion {
    <#
    .SYNOPSIS
        Gets the version from the module manifest.
    #>
    param(
        [VerbosityLevel]$VerbosityLevel = [VerbosityLevel]::All
    )

    try {
        $manifest = Import-PowerShellDataFile -Path 'VideoFunctions.psd1'
        return $manifest.ModuleVersion
    }
    catch {
        Write-InstallationMessage -Message "Failed to read module version from manifest: $($_.Exception.Message)" -Type 'Warning' -VerbosityLevel $VerbosityLevel
        return 'Unknown'
    }
}

function Test-ModuleInstalled {
    <#
    .SYNOPSIS
        Tests if the VideoFunctions module is installed and returns installation locations.
    #>
    param(
        [string]$Scope
    )

    $modulePaths = Get-ModulePath -Scope $Scope
    $installedPaths = @()

    foreach ($path in $modulePaths) {
        if (Test-Path $path) {
            $installedPaths += $path
        }
    }

    return $installedPaths
}

function Get-ModuleInfo {
    <#
    .SYNOPSIS
        Gets module information from a module path.
    #>
    param(
        [string]$ModulePath,
        [VerbosityLevel]$VerbosityLevel = [VerbosityLevel]::All
    )

    try {
        $manifestPath = Join-Path $ModulePath 'VideoFunctions.psd1'
        if (Test-Path $manifestPath) {
            $manifest = Import-PowerShellDataFile -Path $manifestPath
            return @{
                Version     = $manifest.ModuleVersion
                Author      = $manifest.Author
                Description = $manifest.Description
            }
        }
    }
    catch {
        Write-InstallationMessage -Message "Failed to read module info from $ModulePath`: $($_.Exception.Message)" -Type 'Warning' -VerbosityLevel $VerbosityLevel
    }

    return @{
        Version     = 'Unknown'
        Author      = 'Unknown'
        Description = 'Unknown'
    }
}

function Find-VideoFunctionsDirectory {
    <#
    .SYNOPSIS
        Finds the VideoFunctions module directory by searching common locations.
    #>
    $searchPaths = @(
        $PSScriptRoot,
        (Split-Path $PSScriptRoot -Parent),
        (Get-Location).Path,
        "$env:USERPROFILE\Documents\PowerShell\Modules\VideoFunctions",
        "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\VideoFunctions",
        "$env:ProgramFiles\PowerShell\Modules\VideoFunctions",
        "$env:ProgramFiles\WindowsPowerShell\Modules\VideoFunctions"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path (Join-Path $path 'VideoFunctions.psd1')) {
            return $path
        }
    }

    return $null
}

function Build-UninstallParameter {
    <#
    .SYNOPSIS
        Builds the parameter hashtable for the uninstall script.
    #>
    param(
        [string]$Scope,
        [bool]$Force,
        [VerbosityLevel]$Verbosity,
        [bool]$WhatIfPreference,
        [string]$ConfirmPreference
    )

    $params = @{}

    if ($Scope -ne 'All') {
        $params['Scope'] = $Scope
    }

    if ($Force) {
        $params['Force'] = $true
    }

    if ($Verbosity -ne 'All') {
        $params['Verbosity'] = $Verbosity
    }

    if ($WhatIfPreference) {
        $params['WhatIf'] = $true
    }

    if ($ConfirmPreference -eq 'None') {
        $params['Confirm'] = $false
    }

    return $params
}

function Build-InstallParameter {
    <#
    .SYNOPSIS
        Builds the parameter hashtable for the install script.
    #>
    param(
        [string]$Scope,
        [bool]$Force,
        [VerbosityLevel]$Verbosity,
        [bool]$WhatIfPreference,
        [string]$ConfirmPreference
    )

    $params = @{}

    # For install, use CurrentUser if Scope is All, otherwise use the specified scope
    $installScope = if ($Scope -eq 'All') { 'CurrentUser' } else { $Scope }
    $params['Scope'] = $installScope

    if ($Force) {
        $params['Force'] = $true
    }

    if ($Verbosity -ne 'All') {
        $params['Verbosity'] = $Verbosity
    }

    if ($WhatIfPreference) {
        $params['WhatIf'] = $true
    }

    if ($ConfirmPreference -eq 'None') {
        $params['Confirm'] = $false
    }

    return $params
}

# Export all functions and enums
Export-ModuleMember -Function @(
    'Write-InstallationMessage',
    'Test-Administrator',
    'Get-ModuleInstallPath',
    'Get-ModulePath',
    'Test-ModuleStructure',
    'Get-ModuleVersion',
    'Test-ModuleInstalled',
    'Get-ModuleInfo',
    'Find-VideoFunctionsDirectory',
    'Build-UninstallParameter',
    'Build-InstallParameter'
) -Variable @(
    'InstallScope',
    'UninstallScope',
    'ReinstallScope',
    'VerbosityLevel'
)