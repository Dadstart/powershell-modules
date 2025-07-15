function Use-TempDirectory {
    <#
    .SYNOPSIS
        Executes a script block with automatic temporary directory management and cleanup.
    
    .DESCRIPTION
        Creates a temporary directory, executes the provided script block with the temp directory path,
        and automatically cleans up the temporary directory when done. This centralizes the common
        pattern of temporary directory management used across multiple functions.
    
    .PARAMETER ScriptBlock
        The script block to execute with the temporary directory.
    
    .PARAMETER Root
        Optional root path for the temporary directory. Defaults to system temp path.
    
    .EXAMPLE
        Use-TempDirectory -ScriptBlock {
            param($TempDirectory)
            Write-Message "Working in: $TempDirectory" -Type Info
            # Process files in temp directory
        }
    
    .EXAMPLE
        Use-TempDirectory -ScriptBlock {
            param($TempDirectory)
            Copy-Item "source.txt" $TempDirectory
            # Process files
        } -Root "C:\CustomTemp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [string]$Root
    )
    
    $tempDir = New-TempDirectory -Root $Root
    try {
        Write-Message "Created temp directory: $tempDir" -Type Debug
        & $ScriptBlock -TempDirectory $tempDir
    }
    finally {
        if (Test-Path $tempDir) {
            Write-Message "Cleaning up temp directory: $tempDir" -Type Debug
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Message "Temp directory cleaned up: $tempDir" -Type Debug
        }
    }
} 
