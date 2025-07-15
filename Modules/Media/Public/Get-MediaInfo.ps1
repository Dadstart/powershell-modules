function Get-MediaInfo {
    <#
    .SYNOPSIS
        Gets detailed information about media files.
    
    .DESCRIPTION
        Retrieves comprehensive information about media files including metadata,
        technical specifications, and file properties.
    
    .PARAMETER Path
        The path to the media file or directory containing media files.
    
    .PARAMETER Recurse
        If specified, searches for media files recursively in subdirectories.
    
    .PARAMETER MediaType
        Filter by media type. Valid values are 'Video', 'Audio', 'Image', or 'All'.
        Default is 'All'.
    
    .EXAMPLE
        Get-MediaInfo -Path "C:\Videos\movie.mp4"
        
        Returns detailed information about the specified video file.
    
    .EXAMPLE
        Get-MediaInfo -Path "C:\Music" -Recurse -MediaType Audio
        
        Returns information about all audio files in the Music directory and subdirectories.
    
    .EXAMPLE
        Get-MediaInfo -Path "C:\Media" -Recurse | Where-Object { $_.Size -gt 1GB }
        
        Returns information about media files larger than 1GB.
    
    .OUTPUTS
        [MediaFile] Objects containing media file information.
    #>
    [CmdletBinding()]
    [OutputType([MediaFile])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [ValidateSet('Video', 'Audio', 'Image', 'All')]
        [string]$MediaType = 'All'
    )
    
    try {
        # Validate and normalize the path
        $NormalizedPath = Get-Path -Path $Path -MustExist
        
        # Determine if it's a file or directory
        if (Test-Path $NormalizedPath -PathType Leaf) {
            # Single file
            $MediaFile = [MediaFile]::new($NormalizedPath)
            if ($MediaType -eq 'All' -or $MediaFile.MediaType -eq $MediaType) {
                Write-Message -Message "Processing media file: $($MediaFile.Name)" -Level Verbose
                return $MediaFile
            }
        }
        else {
            # Directory - find media files
            $MediaExtensions = @(
                # Video
                '*.mp4', '*.avi', '*.mkv', '*.mov', '*.wmv', '*.flv', '*.webm', '*.m4v',
                # Audio
                '*.mp3', '*.wav', '*.flac', '*.aac', '*.ogg', '*.wma', '*.m4a',
                # Image
                '*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.tiff', '*.webp'
            )
            
            $GetChildItemParams = @{
                Path = $NormalizedPath
                Include = $MediaExtensions
            }
            
            if ($Recurse) {
                $GetChildItemParams['Recurse'] = $true
            }
            
            $MediaFiles = Get-ChildItem @GetChildItemParams
            
            Write-Message -Message "Found $($MediaFiles.Count) media files" -Level Info
            
            foreach ($File in $MediaFiles) {
                $MediaFile = [MediaFile]::new($File.FullName)
                
                if ($MediaType -eq 'All' -or $MediaFile.MediaType -eq $MediaType) {
                    Write-Message -Message "Processing: $($MediaFile.Name)" -Level Verbose
                    $MediaFile
                }
            }
        }
    }
    catch {
        Write-Message -Message "Error getting media info: $_" -Level Error
        throw
    }
} 