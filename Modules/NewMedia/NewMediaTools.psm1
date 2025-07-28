#Requires -Version 7.4

# MediaTools Module Root Script
# This file serves as the entry point for the MediaTools module

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

# Define class dependencies to ensure proper loading order
$classDependencies = @{
    'MediaFormat.ps1' = @()
    'MediaChapter.ps1' = @()
    'MediaStream.ps1' = @()
    'MediaFile.ps1' = @('MediaFormat.ps1', 'MediaChapter.ps1', 'MediaStream.ps1')
    'AudioTrackMapping.ps1' = @()
    'SubtitleTrackMapping.ps1' = @()
    'VideoEncodingSettings.ps1' = @()
    'AudioStreamConfig.ps1' = @()
    'VideoEncodingConfig.ps1' = @()
}

# Load classes in dependency order
$loadedClasses = @()
$classesToLoad = $publicClasses | Sort-Object Name

while ($classesToLoad.Count -gt 0) {
    $loadedThisRound = @()

    foreach ($class in $classesToLoad) {
        $dependencies = $classDependencies[$class.Name]
        $canLoad = $true

        if ($dependencies) {
            foreach ($dep in $dependencies) {
                if ($loadedClasses -notcontains $dep) {
                    $canLoad = $false
                    break
                }
            }
        }

        if ($canLoad) {
            try {
                . $($class.FullName)
                $loadedClasses += $class.Name
                $loadedThisRound += $class
                Write-Verbose "Loaded class: $($class.Name)"
            }
            catch {
                Write-Host "✗ Failed to dot-source $($class.Name): $_" -ForegroundColor Red
            }
        }
    }

    # Remove loaded classes from the queue
    $classesToLoad = $classesToLoad | Where-Object { $loadedThisRound -notcontains $_ }

    # If no classes were loaded this round, we have a circular dependency
    if ($loadedThisRound.Count -eq 0 -and $classesToLoad.Count -gt 0) {
        Write-Warning "Circular dependency detected. Remaining classes: $($classesToLoad.Name -join ', ')"
        break
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
