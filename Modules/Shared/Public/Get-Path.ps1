function Get-Path {
    <#
    .SYNOPSIS
        Gets a standardized path with proper formatting and validation.
    
    .DESCRIPTION
        Provides a centralized way to handle path operations across all modules.
        Ensures consistent path formatting and validation.
    
    .PARAMETER Path
        The path to process and validate.
    
    .PARAMETER PathType
        The type of path expected. Valid values are 'File', 'Directory', or 'Any'.
        Default is 'Any'.
    
    .PARAMETER MustExist
        If specified, the path must exist or an error will be thrown.
    
    .EXAMPLE
        Get-Path -Path "C:\temp\file.txt" -PathType File -MustExist
        
        Returns the normalized path if the file exists, otherwise throws an error.
    
    .EXAMPLE
        Get-Path -Path "C:\temp" -PathType Directory
        
        Returns the normalized directory path without checking existence.
    
    .OUTPUTS
        [string] The normalized and validated path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet('File', 'Directory', 'Any')]
        [string]$PathType = 'Any',
        
        [Parameter()]
        [switch]$MustExist
    )
    
    try {
        # Normalize the path
        $NormalizedPath = [System.IO.Path]::GetFullPath($Path)
        
        # Validate path type if specified
        if ($PathType -ne 'Any') {
            if ($PathType -eq 'File' -and (Test-Path $NormalizedPath -PathType Container)) {
                throw "Path '$NormalizedPath' is a directory, but a file was expected."
            }
            elseif ($PathType -eq 'Directory' -and (Test-Path $NormalizedPath -PathType Leaf)) {
                throw "Path '$NormalizedPath' is a file, but a directory was expected."
            }
        }
        
        # Check existence if required
        if ($MustExist -and -not (Test-Path $NormalizedPath)) {
            throw "Path '$NormalizedPath' does not exist."
        }
        
        return $NormalizedPath
    }
    catch {
        throw "Path validation failed: $_"
    }
} 