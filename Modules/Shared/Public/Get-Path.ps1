function Get-Path {
    <#
    .SYNOPSIS
        Resolves and processes file system paths with cross-platform support.
    .DESCRIPTION
        Processes file system paths and returns the resolved path based on the specified PathType.
        Can resolve relative paths to absolute paths and optionally create directories.
    .PARAMETER Path
        One or more file system paths to process. Multiple paths are combined into a single path.
        Must be specified with the -Path parameter name.
    .PARAMETER PathType
        Specifies the type of path information to return. This parameter is based on Split-Path functionality.
        - Parent: Returns the parent directory path (e.g., "C:\folder" from "C:\folder\file.txt")
        - Absolute: Returns the absolute path resolved relative to current location
        - Relative: Returns the path relative to current location
        - Leaf: Returns only the file or folder name (e.g., "file.txt" from "C:\folder\file.txt")
        - LeafBase: Returns the file or folder name without the extension (e.g., "file" from "C:\folder\file.txt")
        - Extension: Returns only the file extension including the dot (e.g., ".txt" from "C:\folder\file.txt")
        - Qualifier: Returns the drive qualifier (e.g., "C:" from "C:\folder\file.txt")
        - NoQualifier: Returns the path without the drive qualifier (e.g., "\folder\file.txt" from "C:\folder\file.txt")
    .PARAMETER Create
        Specifies the type of item to create if the path doesn't exist. This parameter is mutually exclusive with ValidatePath.
        - File: Creates the file and its parent directory if needed
        - Directory: Creates the directory and its parent directories if needed
        - None: No creation performed (default)
    .PARAMETER ValidatePath
        Specifies the type of path validation to perform. This parameter ensures the path exists and is of the expected type.
        This parameter is mutually exclusive with Create.
        - File: Validates that the path exists and is a file
        - Directory: Validates that the path exists and is a directory
        - Either: Validates that the path exists (can be either file or directory)
        - None: No validation performed (default)
    .PARAMETER ValidationErrorAction
        Specifies how to handle validation errors when ValidatePath is specified.
        - Stop: Throws an exception if validation fails (default)
        - Continue: Returns $null if validation fails
        - SilentlyContinue: Returns $null if validation fails without error messages
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -PathType Parent
        Returns: "C:\folder"
    .EXAMPLE
        Get-Path -Path "subfolder\file.txt" -PathType Absolute
        Returns: "C:\current\location\subfolder\file.txt"
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -PathType Leaf
        Returns: "file.txt"
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -PathType LeafBase
        Returns: "file"
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -PathType Extension
        Returns: ".txt"
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -PathType Qualifier
        Returns: "C:"
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -PathType NoQualifier
        Returns: "\folder\file.txt"
    .EXAMPLE
        Get-Path -Path "C:\new\folder\path" -PathType Absolute -Create Directory
        Creates the directory structure and returns: "C:\new\folder\path"
    .EXAMPLE
        Get-Path -Path "C:\new\folder\file.txt" -PathType Absolute -Create File
        Creates the parent directory and empty file, returns: "C:\new\folder\file.txt"
    .EXAMPLE
        Get-Path -Path "/home/user/folder" -PathType Relative
        Returns: "..\..\home\user\folder" (relative to current location)
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -ValidatePath File
        Returns: "C:\folder\file.txt" if the file exists, throws error if not
    .EXAMPLE
        Get-Path -Path "C:\folder" -ValidatePath Directory
        Returns: "C:\folder" if the directory exists, throws error if not
    .EXAMPLE
        Get-Path -Path "C:\folder\file.txt" -ValidatePath Either -ValidationErrorAction Continue
        Returns: "C:\folder\file.txt" if path exists, $null if not
    .EXAMPLE
        Get-Path -Path "C:\nonexistent\file.txt" -ValidatePath File -ValidationErrorAction SilentlyContinue
        Returns: $null without error messages
    .EXAMPLE
        Get-Path -Path "C:\folder", "subfolder", "file.txt" -PathType Absolute
        Returns: "C:\folder\subfolder\file.txt" (combines multiple path components)
    .NOTES
        This function provides a unified interface for path processing operations using .NET functions for cross-platform compatibility.
        Root directories (like "C:" on Windows or "/" on Unix) are automatically detected and not created.
        The ValidatePath parameter combines the functionality of Test-Path with path type validation,
        providing a convenient way to ensure paths exist and are of the expected type before processing.
        The Create parameter provides functionality similar to New-Item, allowing creation of files or directories
        with automatic parent directory creation when needed.
        Note: Create and ValidatePath are mutually exclusive parameters. Use Create when you want to ensure
        the path exists by creating it, or use ValidatePath when you want to verify an existing path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Path,
        [Parameter()]
        [ValidateSet('Parent', 'Absolute', 'Relative', 'Leaf', 'LeafBase', 'Extension', 'Qualifier', 'NoQualifier')]
        [string]$PathType = 'Absolute',
        [Parameter()]
        [ValidateSet('None', 'File', 'Directory')]
        [string]$Create = 'None',
        [Parameter()]
        [ValidateSet('None', 'File', 'Directory', 'Either')]
        [string]$ValidatePath = 'None',
        [Parameter()]
        [ValidateSet('Stop', 'Continue', 'SilentlyContinue')]
        [string]$ValidationErrorAction = 'Stop'
    )
    Write-Message "Path: $Path" -Type Verbose
    Write-Message "PathType: $PathType" -Type Verbose
    Write-Message "Create: $Create" -Type Verbose
    Write-Message "ValidatePath: $ValidatePath" -Type Verbose
    Write-Message "ValidationErrorAction: $ValidationErrorAction" -Type Verbose

    # Validate that Create and ValidatePath are not both specified
    if ($Create -ne 'None' -and $ValidatePath -ne 'None') {
        throw 'Parameters Create and ValidatePath are mutually exclusive. Use Create to create a path or ValidatePath to validate an existing path, but not both.'
    }

    $combinedPath = [System.IO.Path]::Combine($Path)
    Write-Message "CombinedPath: $combinedPath" -Type Verbose

    # Resolve relative to current directory if the path is not already absolute
    if ([System.IO.Path]::IsPathRooted($combinedPath)) {
        $absolutePath = [System.IO.Path]::GetFullPath($combinedPath)
    }
    else {
        $currentDir = (Get-Location).Path
        $absolutePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($currentDir, $combinedPath))
    }
    Write-Message "AbsolutePath: $absolutePath" -Type Verbose

    # Perform path validation if requested
    if ($ValidatePath -ne 'None') {
        $validationResult = $true
        $validationMessage = ''
        switch ($ValidatePath) {
            'File' {
                if (-not [System.IO.File]::Exists($absolutePath)) {
                    $validationResult = $false
                    $validationMessage = "File does not exist: '$absolutePath'"
                }
            }
            'Directory' {
                if (-not [System.IO.Directory]::Exists($absolutePath)) {
                    $validationResult = $false
                    $validationMessage = "Directory does not exist: '$absolutePath'"
                }
            }
            'Either' {
                if (-not [System.IO.File]::Exists($absolutePath) -and -not [System.IO.Directory]::Exists($absolutePath)) {
                    $validationResult = $false
                    $validationMessage = "Path does not exist: '$absolutePath'"
                }
            }
        }
        if (-not $validationResult) {
            switch ($ValidationErrorAction) {
                'Stop' {
                    throw $validationMessage
                }
                'Continue' {
                    Write-Message $validationMessage -Type Warning
                    return $null
                }
                'SilentlyContinue' {
                    return $null
                }
            }
        }
    }

    # Process the path based on PathType
    switch ($PathType) {
        'Parent' {
            $finalPath = [System.IO.Path]::GetDirectoryName($absolutePath)
        }
        'Absolute' {
            $finalPath = $absolutePath
        }
        'Relative' {
            $currentLocation = [System.IO.Directory]::GetCurrentDirectory()
            $finalPath = [System.IO.Path]::GetRelativePath($currentLocation, $absolutePath)
        }
        'Leaf' {
            $finalPath = [System.IO.Path]::GetFileName($absolutePath)
        }
        'LeafBase' {
            $finalPath = [System.IO.Path]::GetFileNameWithoutExtension($absolutePath)
        }
        'Extension' {
            $finalPath = [System.IO.Path]::GetExtension($absolutePath)
        }
        'Qualifier' {
            $finalPath = [System.IO.Path]::GetPathRoot($absolutePath)
        }
        'NoQualifier' {
            $root = [System.IO.Path]::GetPathRoot($absolutePath)
            if ($root) {
                $finalPath = $absolutePath.Substring($root.Length)
            }
            else {
                $finalPath = $absolutePath
            }
        }
    }

    # Create item if requested
    if ($Create -ne 'None') {
        switch ($Create) {
            'Directory' {
                if (-not [System.IO.Directory]::Exists($finalPath)) {
                    [System.IO.Directory]::CreateDirectory($finalPath) | Out-Null
                    Write-Message "Created directory: '$finalPath'" -Type Verbose
                }
                else {
                    Write-Message "Directory already exists: '$finalPath'" -Type Verbose
                }
            }
            'File' {
                # Ensure parent directory exists
                $parentDirectory = [System.IO.Path]::GetDirectoryName($finalPath)
                if (-not [string]::IsNullOrEmpty($parentDirectory) -and -not [System.IO.Directory]::Exists($parentDirectory)) {
                    [System.IO.Directory]::CreateDirectory($parentDirectory) | Out-Null
                    Write-Message "Created parent directory: '$parentDirectory'" -Type Verbose
                }
                # Create the file if it doesn't exist
                if (-not [System.IO.File]::Exists($finalPath)) {
                    [System.IO.File]::Create($finalPath).Close()
                    Write-Message "Created file: '$finalPath'" -Type Verbose
                }
                else {
                    Write-Message "File already exists: '$finalPath'" -Type Verbose
                }
            }
        }
    }
    return $finalPath
}
