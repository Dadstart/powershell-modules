function Get-ValidationAttributes {
    <#
    .SYNOPSIS
        Provides DVD module-specific validation attributes for parameter validation patterns.
    
    .DESCRIPTION
        This function returns validation attributes specific to DVD processing operations
        including HandBrake encoder settings, chapter ranges, and DVD-specific patterns.
    
    .EXAMPLE
        # Get all validation attributes
        $validators = Get-ValidationAttributes
        
    .EXAMPLE
        # Use in parameter validation
        [int]$Quality
        
    .OUTPUTS
        [PSCustomObject] Object containing validation patterns and custom validation functions.
    
    .NOTES
        These validation patterns are specific to DVD processing operations
        and should only be used within the DVD module.
    #>
    
    return @{
        # Chapter range validation - matches "1", "1-3", or empty string
        ChapterRangePattern = '^(\d+(-\d+)?)?$'
        
        # Language code validation - 2-3 letter language codes
        LanguagePattern = '^[a-z]{2,3}$'
    }
}

