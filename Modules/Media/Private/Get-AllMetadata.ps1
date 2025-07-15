function Get-AllMetadata {
    <#
    .SYNOPSIS
        Private function to extract all metadata from media files.
    
    .DESCRIPTION
        Extracts comprehensive metadata including basic, technical, and tag information.
        This is a private function called by the public Get-MediaMetadata function.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaFile]$MediaFile,
        
        [Parameter()]
        [switch]$IncludeEmpty
    )
    
    try {
        Write-Message -Message "Extracting all metadata from $($MediaFile.Name)" -Level Verbose
        
        # Combine all metadata types
        $BasicMetadata = Get-BasicMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
        $TechnicalMetadata = Get-TechnicalMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
        $TagMetadata = Get-TagMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
        
        # Create comprehensive metadata object
        $AllMetadata = [PSCustomObject]@{
            FileName = $MediaFile.Name
            FilePath = $MediaFile.Path
            MediaType = $MediaFile.MediaType
            Basic = $BasicMetadata
            Technical = $TechnicalMetadata
            Tags = $TagMetadata
            ExtractionTime = Get-Date
        }
        
        return $AllMetadata
    }
    catch {
        Write-Message -Message "Error extracting all metadata: $_" -Level Error
        return $null
    }
} 