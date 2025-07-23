function Move-GitDirectory {
<#
.SYNOPSIS
    Move all files from one directory to another using git mv.
.DESCRIPTION
    This function moves all files and directories from a source directory to a target directory
    using git mv to preserve git history. It also handles renaming of module files appropriately.
.PARAMETER Source
    The source directory path (relative to repository root).
.PARAMETER Target
    The target directory path (relative to repository root).
.PARAMETER Force
    Force the operation even if target directory already has content.
.EXAMPLE
    Move-GitDirectory -Source "PowerShell\Video" -Target "PowerShell\VideoUtility"
    Moves all files from PowerShell\Video to PowerShell\VideoUtility directory.
.EXAMPLE
    Move-GitDirectory -Source "PowerShell\Video" -Target "PowerShell\VideoUtility" -Force
    Forces the move operation even if target directory has content.
.NOTES
    This function should be run from the repository root directory.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Target,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    #Requires -Version 7.0
    # Get the repository root directory
    $pathRoot = Get-Location
    $sourceDir = Get-Path -Path $Source -PathType Absolute -ValidatePath Directory
    $targetDir = Get-Path -Path $Target -PathType Absolute -Create Directory
    Write-Message "Moving files from '$Source' to '$Target' directory..." -Type Verbose
    # Check if source directory exists
    Write-Message "Checking if source directory exists: $sourceDir" -Type Debug
    if (-not (Test-Path $sourceDir)) {
        Write-Message "Source directory not found: $sourceDir" -Type Error
        return
    }
    Write-Message "Source directory exists" -Type Debug
    # Check if destination directory has content
    Write-Message "Checking destination directory content" -Type Debug
    $destinationContent = Get-ChildItem -Path $targetDir -Force
    if ($destinationContent -and -not $Force) {
        Write-Message "Target directory contains files and -Force not specified: `n$($destinationContent -join "`n")" -Type Debug
        Write-Message "Target directory already contains files. Use -Force to ignore." -Type Warning
        return
    }
    Write-Message "Target directory is empty or Force is specified" -Type Debug
    # Change to repository root for git operations
    Write-Message "Changing to repository root: $pathRoot" -Type Debug
    Push-Location $pathRoot
    try {
        # Get all files and directories in the source directory
        Write-Message "Getting items from source directory: $sourceDir" -Type Debug
        $items = Get-ChildItem -Path $sourceDir -Force
        Write-Message "Found $($items.Count) items to move" -Type Verbose
        foreach ($item in $items) {
            $sourcePath = $item.FullName
            $relativeSourcePath = $sourcePath.Replace($pathRoot, "").TrimStart("\")
            $relativeDestPath = $relativeSourcePath.Replace($Source, $Target)
            Write-Message "Processing item: $($item.Name) (Type: $($item.PSIsContainer))" -Type Debug
            if ($item.PSIsContainer) {
                # Handle directories
                $destPath = Get-Path -Path $targetDir, $item.Name -PathType Absolute -Create Directory
                Write-Message "Directory destination path: $destPath" -Type Debug
                # Move contents of directory
                Write-Message "Getting sub-items from directory: $sourcePath" -Type Debug
                $subItems = Get-ChildItem -Path $sourcePath -Force
                Write-Message "Found $($subItems.Count) sub-items to move" -Type Debug
                foreach ($subItem in $subItems) {
                    $subSourcePath = $subItem.FullName
                    $subDestPath = Get-Path -Path $destPath, $subItem.Name -PathType Absolute
                    Write-Message "Moving sub-item: $($subItem.Name) from $subSourcePath to $subDestPath" -Type Verbose
                    git mv $subSourcePath $subDestPath
                }
                # Remove empty source directory
                Write-Message "Removing empty source directory: $sourcePath" -Type Debug
                Remove-Item -Path $sourcePath -Force
            } else {
                # Handle files
                $destPath = Get-Path -Path $targetDir, $item.Name -PathType Absolute
                Write-Message "File destination path: $destPath" -Type Debug
                # Special handling for module files - detect source module name and rename accordingly
                $sourceModuleName = Get-Path -Path $Source -PathType Leaf
                $targetModuleName = Get-Path -Path $Target -PathType Leaf
                Write-Message "Source module name: $sourceModuleName, Target module name: $targetModuleName" -Type Verbose
                if ($item.Name -eq "$sourceModuleName.psd1") {
                    $destPath = Get-Path -Path $targetDir, "$targetModuleName.psd1" -PathType Absolute
                    Write-Message "Renaming module manifest: $($item.Name) -> $targetModuleName.psd1" -Type Debug
                } elseif ($item.Name -eq "$sourceModuleName.psm1") {
                    $destPath = Get-Path -Path $targetDir, "$targetModuleName.psm1" -PathType Absolute
                    Write-Message "Renaming module script: $($item.Name) -> $targetModuleName.psm1" -Type Debug
                }
                Write-Message "Executing git mv: $sourcePath -> $destPath" -Type Debug
                git mv $sourcePath $destPath
            }
        }
        Write-Message "All files moved successfully!" -Type Verbose
        Write-Message "Source directory: $sourceDir" -Type Debug
        Write-Message "Target directory: $targetDir" -Type Debug
        # Show what was moved
        $movedFiles = Get-ChildItem -Path $targetDir -Recurse | ForEach-Object {
            $relativePath = $_.FullName.Replace($targetDir, "").TrimStart("\")
            $relativePath
        }
        Write-Message "`nMoved files:`n$($movedFiles -join "`n")" -Type Verbose
    } catch {
        Write-Message "Error during file move operation: $($_.Exception.Message)" -Type Error
        throw
    } finally {
        # Restore original location
        Write-Message "Restoring original location" -Type Debug
        Pop-Location
    }
    Write-Message "Function completed successfully!" -Type Verbose
}
