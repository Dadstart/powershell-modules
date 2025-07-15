function Get-MediaMetadata {
    <#
    .SYNOPSIS
        Gets metadata from media files.
    
    .DESCRIPTION
        Extracts and returns detailed metadata from media files including technical
        specifications, tags, and other file information.
    
    .PARAMETER Path
        The path to the media file or directory containing media files.
    
    .PARAMETER Recurse
        If specified, processes media files recursively in subdirectories.
    
    .PARAMETER MetadataType
        The type of metadata to extract. Valid values are 'All', 'Technical', 'Tags', 'Basic'.
        Default is 'All'.
    
    .PARAMETER IncludeEmpty
        If specified, includes properties with empty values in the output.
    
    .EXAMPLE
        Get-MediaMetadata -Path "C:\Videos\movie.mp4"
        
        Returns all metadata for the specified video file.
    
    .EXAMPLE
        Get-MediaMetadata -Path "C:\Music" -Recurse -MetadataType Technical
        
        Returns technical metadata for all audio files in the directory.
    
    .EXAMPLE
        Get-MediaMetadata -Path "C:\Images\photo.jpg" -MetadataType Tags
        
        Returns only tag metadata for the image file.
    
    .OUTPUTS
        [PSCustomObject] Objects containing metadata information.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [ValidateSet('All', 'Technical', 'Tags', 'Basic')]
        [string]$MetadataType = 'All',
        
        [Parameter()]
        [switch]$IncludeEmpty
    )
    
    try {
        # Validate and normalize the path
        $NormalizedPath = Get-Path -Path $Path -MustExist
        
        # Get media files
        $MediaFiles = Get-MediaInfo -Path $NormalizedPath -Recurse:$Recurse
        
        $MetadataResults = @()
        
        foreach ($MediaFile in $MediaFiles) {
            Write-Message -Message "Extracting metadata from $($MediaFile.Name)" -Level Verbose
            
            # Extract metadata based on type
            $Metadata = switch ($MetadataType) {
                'All' {
                    Get-AllMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
                }
                'Technical' {
                    Get-TechnicalMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
                }
                'Tags' {
                    Get-TagMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
                }
                'Basic' {
                    Get-BasicMetadata -MediaFile $MediaFile -IncludeEmpty:$IncludeEmpty
                }
            }
            
            if ($Metadata) {
                $MetadataResults += $Metadata
            }
        }
        
        return $MetadataResults
    }
    catch {
        Write-Message -Message "Error extracting metadata: $_" -Level Error
        throw
    }
} 