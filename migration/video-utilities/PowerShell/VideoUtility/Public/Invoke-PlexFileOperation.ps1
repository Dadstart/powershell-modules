function Invoke-PlexFileOperation {
    <#
    .SYNOPSIS
        Invokes all Plex file and folder operations.

    .DESCRIPTION
        This function takes a source and destination where the Plex movie exists and performs all Plex organization operations.

    .PARAMETER Source
        Source path where the bonus content files are located.

    .PARAMETER Destination
        Destination path of the Plex bonus content files.

    .PARAMETER Force
        Overwrites existing files without prompting. By default, the function will skip files that already exist.

    .EXAMPLE
        Invoke-PlexFileOperation -Source 'C:\downloads\My Movie' -Destination 'C:\plex\movies\My Movie'

        Executes the following commands:
        - Add-PlexFolder $Destination
        - Move-PlexFile -Source $Source -Destination $Destination
        - Remove-PlexEmptyFolder $Destination

    .EXAMPLE
        Invoke-PlexFileOperation -Source 'C:\downloads\My Movie' -Destination 'C:\plex\movies\My Movie' -Force

        Executes the same operations but with -Force parameter passed to Move-PlexFile.

    .INPUTS
        [string] - The source and destination paths

    .OUTPUTS
        None. Performs file and folder operations.

    .NOTES
        This function is a convenience wrapper that performs all Plex organization operations in sequence.
        The -Force parameter is passed through to Move-PlexFile to control file overwrite behavior.
        
        Error handling is implemented for each operation:
        - Path validation before starting operations
        - Individual error handling for each Plex operation
        - Detailed error messages for troubleshooting
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination,
        [Parameter()]
        [switch]$Force
    )

    Write-Host "Organizing files from $Source into Plex directory $Destination" -ForegroundColor Cyan

    # Validate paths before starting any operations
    try {
        if (-not (Test-Path -Path $Destination -PathType Container)) {
            throw "Destination folder does not exist or is not a directory: '$Destination'"
        }
        if (-not (Test-Path -Path $Source -PathType Container)) {
            throw "Source folder does not exist or is not a directory: '$Source'"
        }
    }
    catch {
        Write-Error "Path validation failed: $($_.Exception.Message)" -ErrorAction Stop
    }

    $operationsCompleted = @()
    $operationsFailed = @()

    # Step 1: Create Plex folders
    try {
        Write-Verbose "Creating Plex folder structure in: $Destination"
        Add-PlexFolder -Destination $Destination
        $operationsCompleted += "Add-PlexFolder"
        Write-Verbose "Successfully created Plex folder structure"
    }
    catch {
        $errorMsg = "Failed to create Plex folder structure: $($_.Exception.Message)"
        Write-Error $errorMsg -ErrorAction Continue
        $operationsFailed += "Add-PlexFolder"
        
        # If folder creation fails, we can't proceed with file operations
        Write-Warning "Cannot proceed with file operations without Plex folder structure. Stopping operation."
        return
    }

    # Step 2: Move files to Plex folders
    try {
        Write-Verbose "Moving files from '$Source' to Plex folders in '$Destination'"
        Move-PlexFile -Source $Source -Destination $Destination -Force:$Force
        $operationsCompleted += "Move-PlexFile"
        Write-Verbose "Successfully moved files to Plex folders"
    }
    catch {
        $errorMsg = "Failed to move files to Plex folders: $($_.Exception.Message)"
        Write-Error $errorMsg -ErrorAction Continue
        $operationsFailed += "Move-PlexFile"
        
        # Continue with cleanup even if file move failed
        Write-Warning "File move operation failed, but will attempt to clean up empty folders."
    }

    # Step 3: Remove empty folders (cleanup)
    try {
        Write-Verbose "Removing empty Plex folders from: $Destination"
        Remove-PlexEmptyFolder -Destination $Destination
        $operationsCompleted += "Remove-PlexEmptyFolder"
        Write-Verbose "Successfully removed empty Plex folders"
    }
    catch {
        $errorMsg = "Failed to remove empty Plex folders: $($_.Exception.Message)"
        Write-Error $errorMsg -ErrorAction Continue
        $operationsFailed += "Remove-PlexEmptyFolder"
    }

    # Summary of operations
    if ($operationsCompleted.Count -eq 3) {
        Write-Host "All Plex file operations completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Warning "Plex file operations completed with some failures:"
        Write-Warning "  Completed: $($operationsCompleted -join ', ')"
        Write-Warning "  Failed: $($operationsFailed -join ', ')"
        
        if ($operationsFailed.Count -eq 3) {
            Write-Error "All Plex file operations failed. Please check the error messages above and verify your paths and permissions." -ErrorAction Continue
        }
    }
}