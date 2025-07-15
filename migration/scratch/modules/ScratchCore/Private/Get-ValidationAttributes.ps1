function Get-ValidationAttributes {
    <#
    .SYNOPSIS
        Provides generic validation attributes for common parameter validation patterns.
    
    .DESCRIPTION
        This function returns generic validation attributes that can be used across all modules
        for basic validation patterns. These attributes provide more specific validation than 
        the built-in PowerShell validation attributes but are domain-agnostic.
    
    .EXAMPLE
        # Get all validation attributes
        $validators = Get-ValidationAttributes
        
    .EXAMPLE
        # Use in parameter validation
        [ValidateScript($Script:ValidateFilePatternScript)]
        [string]$Filename
        
    .OUTPUTS
        [PSCustomObject] Object containing validation patterns and custom validation functions.
    
    .NOTES
        These validation script blocks are designed to be reusable across all modules
        and provide consistent validation behavior for generic patterns.
        
        Usage in parameter declarations:
        [ValidateScript($Script:ValidateFilePatternScript)]
        [string]$Filename
    #>
    
    return @{
        # File pattern validation - allows letters, numbers, dots, hyphens, underscores, and wildcards
        FilePattern = '^[\w\*\.\-\?]+$'
        
        # Path validation patterns
        WindowsPathPattern = '^[a-zA-Z]:\\[^*?"<>|]*$'
        UnixPathPattern = '^[^<>:"|?*]+$'
        
        # Generic validation functions
        ValidateFileExists = {
            param([string]$Path)
            if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path $Path)) {
                throw "File does not exist: $Path"
            }
        }
        
        ValidateDirectoryExists = {
            param([string]$Path)
            if (-not [string]::IsNullOrWhiteSpace($Path) -and -not (Test-Path $Path -PathType Container)) {
                throw "Directory does not exist: $Path"
            }
        }
        
        ValidatePositiveNumber = {
            param([object]$Value)
            if ($Value -le 0) {
                throw "Value must be greater than 0: $Value"
            }
        }
        
        ValidateNonNegativeNumber = {
            param([object]$Value)
            if ($Value -lt 0) {
                throw "Value must be non-negative: $Value"
            }
        }
        
        ValidateFileSize = {
            param([long]$Size)
            if ($Size -lt 0) {
                throw "File size must be non-negative: $Size"
            }
            if ($Size -gt 1TB) {
                throw "File size seems unreasonably large: $Size"
            }
        }
    }
}

# Validation script blocks for use with ValidateScript attribute
# Note: These script blocks can be used directly with [ValidateScript()] in parameter declarations

$Script:ValidateFilePatternScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ([string]::IsNullOrWhiteSpace($Value))
    {
        return $true
    }
    
    if ($Value -match '^[\w\*\.\-\?]+$')
    {
        return $true
    }
    
    throw "File pattern must contain only letters, numbers, dots, hyphens, underscores, and wildcards: '$Value'"
}

$Script:ValidateFileExistsScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        return $true
    }
    
    if (Test-Path -Path $Path -PathType Leaf)
    {
        return $true
    }
    
    throw "File does not exist: '$Path'"
}

$Script:ValidateDirectoryExistsScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        return $true
    }
    
    if (Test-Path -Path $Path -PathType Container)
    {
        return $true
    }
    
    throw "Directory does not exist: '$Path'"
}

$Script:ValidatePositiveNumberScript = {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value
    )
    
    if ($Value -gt 0)
    {
        return $true
    }
    
    throw "Value must be greater than 0: '$Value'"
}

$Script:ValidateNonNegativeNumberScript = {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value
    )
    
    if ($Value -ge 0)
    {
        return $true
    }
    
    throw "Value must be non-negative: '$Value'"
} 