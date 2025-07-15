function Get-ValidationAttributes {
    <#
    .SYNOPSIS
        Provides Video module-specific validation attributes for parameter validation patterns.
    
    .DESCRIPTION
        This function returns validation attributes specific to video processing operations
        including episode patterns, season numbers, language codes, and video-specific patterns.
    
    .EXAMPLE
        # Get all validation attributes
        $validators = Get-ValidationAttributes
        
    .EXAMPLE
        # Use in parameter validation
        [string]$EpisodePattern
        
    .OUTPUTS
        [PSCustomObject] Object containing validation patterns and custom validation functions.
    
    .NOTES
        These validation patterns are specific to video processing operations
        and should only be used within the Video module.
    #>
    
    return @{
        # Episode pattern validation - matches S01E01 or s01e01 format
        EpisodePattern = '^[Ss]\d{2}[Ee]\d{2}$'
        
        # Season pattern validation - matches S01 or s01 format
        SeasonPattern = '^[Ss]\d{2}$'
        
        # Language code validation - 2-3 letter language codes
        LanguagePattern = '^[a-z]{2,3}$'
        
        # File extension validation - common video/audio extensions
        VideoExtensionPattern = '\.(mkv|mp4|avi|mov|wmv|flac|webm|m4v)$'
        AudioExtensionPattern = '\.(mp3|aac|flac|wav|ogg|m4a|wma)$'
    }
}
