function Resolve-InputPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateDirectoryExistsAttribute()]
        [string]$Path
    )

    try {
        Write-Message "Resolving path: $Path" -Type Verbose
        $resolvedPath = Get-Path -Path $Path -PathType Absolute
        Write-Message "Resolved path: $resolvedPath" -Type Verbose
        
        return $resolvedPath
    }
    catch {
        Write-Message "Resolve-InputPath function failed with error: $($_.Exception.Message)" -Type Verbose
        Write-Message "Failed to resolve path: $($_.Exception.Message)" -Type Error
        throw "Failed to resolve path: $($_.Exception.Message)"
    }
} 
