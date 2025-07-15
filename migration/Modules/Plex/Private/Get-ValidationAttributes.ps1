function Get-ValidationAttributes {
    <#
    .SYNOPSIS
        Provides Plex-specific validation attributes for parameter validation patterns.
    
    .DESCRIPTION
        This function returns Plex-specific validation attributes that can be used across
        the Plex module for validation patterns specific to Plex server interactions.
        These attributes provide validation for Plex server URLs, tokens, and other
        Plex-specific parameters.
    
    .EXAMPLE
        # Get all validation attributes
        $validators = Get-ValidationAttributes
        
    .EXAMPLE
        # Use in parameter validation
        [ValidateScript($Script:ValidatePlexUrlScript)]
        [string]$PlexUrl
        
    .OUTPUTS
        [PSCustomObject] Object containing validation patterns and custom validation functions.
    
    .NOTES
        These validation script blocks are designed specifically for Plex module
        and provide consistent validation behavior for Plex-specific patterns.
        
        Usage in parameter declarations:
        [ValidateScript($Script:ValidatePlexUrlScript)]
        [string]$PlexUrl
    #>
    
    return @{
        # Plex URL validation patterns
        PlexUrlPattern = '^https?://[^\s/$.?#].[^\s]*$'
        PlexTokenPattern = '^[a-zA-Z0-9_-]+$'
        
        # Plex-specific validation functions
        ValidatePlexUrl = {
            param([string]$Url)
            if (-not [string]::IsNullOrWhiteSpace($Url)) {
                if ($Url -notmatch '^https?://[^\s/$.?#].[^\s]*$') {
                    throw "Invalid Plex URL format: $Url"
                }
            }
        }
        
        ValidatePlexToken = {
            param([string]$Token)
            if (-not [string]::IsNullOrWhiteSpace($Token)) {
                if ($Token -notmatch '^[a-zA-Z0-9_-]+$') {
                    throw "Invalid Plex token format: $Token"
                }
            }
        }
        
        ValidatePlexPort = {
            param([int]$Port)
            if ($Port -lt 1 -or $Port -gt 65535) {
                throw "Port must be between 1 and 65535: $Port"
            }
        }
        
        ValidateLibraryId = {
            param([int]$LibraryId)
            if ($LibraryId -le 0) {
                throw "Library ID must be greater than 0: $LibraryId"
            }
        }
        
        ValidateMediaId = {
            param([int]$MediaId)
            if ($MediaId -le 0) {
                throw "Media ID must be greater than 0: $MediaId"
            }
        }
    }
}

# Validation script blocks for use with ValidateScript attribute
# Note: These script blocks can be used directly with [ValidateScript()] in parameter declarations

$Script:ValidatePlexUrlScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ([string]::IsNullOrWhiteSpace($Value))
    {
        return $true
    }
    
    if ($Value -match '^https?://[^\s/$.?#].[^\s]*$')
    {
        return $true
    }
    
    throw "Invalid Plex URL format: '$Value'. Must be a valid HTTP or HTTPS URL."
}

$Script:ValidatePlexTokenScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ([string]::IsNullOrWhiteSpace($Value))
    {
        return $true
    }
    
    if ($Value -match '^[a-zA-Z0-9_-]+$')
    {
        return $true
    }
    
    throw "Invalid Plex token format: '$Value'. Must contain only letters, numbers, hyphens, and underscores."
}

$Script:ValidatePlexPortScript = {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Value
    )
    
    if ($Value -ge 1 -and $Value -le 65535)
    {
        return $true
    }
    
    throw "Port must be between 1 and 65535: '$Value'"
}

$Script:ValidateLibraryIdScript = {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Value
    )
    
    if ($Value -gt 0)
    {
        return $true
    }
    
    throw "Library ID must be greater than 0: '$Value'"
}

$Script:ValidateMediaIdScript = {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Value
    )
    
    if ($Value -gt 0)
    {
        return $true
    }
    
    throw "Media ID must be greater than 0: '$Value'"
} 