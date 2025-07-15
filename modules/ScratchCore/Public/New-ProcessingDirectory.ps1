function New-ProcessingDirectory {
    <#
    .SYNOPSIS
        Creates a directory if it doesn't exist and provides consistent messaging.
    
    .DESCRIPTION
        New-ProcessingDirectory centralizes the common pattern of creating directories
        with consistent messaging and error handling. This function replaces the repeated
        pattern of calling Confirm-Path followed by output messages.
        
        The function will:
        - Create the directory if it doesn't exist
        - Display a consistent message when a directory is created
        - Return the resolved path for further use
        - Handle errors gracefully
    
    .PARAMETER Path
        The directory path to create. Can be relative or absolute.
    
    .PARAMETER Description
        A human-readable description of the directory being created.
        Used in the success message when the directory is created.
    
    .PARAMETER SuppressOutput
        When specified, suppresses the creation message output.
        Useful when you only need the directory created without messaging.
    
    .EXAMPLE
        $seasonDir = New-ProcessingDirectory -Path ".\MyShow\Season 01" -Description "season"
        
        Creates the season directory and displays: "Created season directory: .\MyShow\Season 01"
    
    .EXAMPLE
        $chapterDir = New-ProcessingDirectory -Path ".\Chapters" -Description "chapter" -SuppressOutput
        
        Creates the chapter directory silently without displaying a message.
    
    .EXAMPLE
        $rootDir = New-ProcessingDirectory -Path "C:\Videos\Breaking Bad" -Description "show root"
        
        Creates the show root directory and displays: "Created show root directory: C:\Videos\Breaking Bad"
    
    .OUTPUTS
        [string] The resolved absolute path of the created directory.
    
    .NOTES
        This function is part of the refactoring effort to reduce code duplication
        and improve consistency across the DVD and Video modules.
        
        The function uses Confirm-Path internally for directory creation and validation.
        If the directory already exists, no message is displayed and the resolved path is returned.
        
        Error handling is consistent with other module functions.
    
    .LINK
        Confirm-Path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter()]
        [switch]$SuppressOutput
    )

    try {
        Write-Message "New-ProcessingDirectory: Creating directory '$Path' with description '$Description'" -Type Debug

        $pathAbs = Get-Path -Path $Path -PathType Absolute -Create Directory
        Write-Message "New-ProcessingDirectory: Returning resolved path: $pathAbs" -Type Debug
        
        return $pathAbs
    }
    catch {
        Write-Message "Failed to create directory '$Path': $($_.Exception.Message)" -Type Error
        Write-Message "Stack trace: $($_.ScriptStackTrace)" -Type Verbose
        throw
    }
} 