class MediaFile {
    <#
    .SYNOPSIS
        Represents a media file with properties and methods for media operations.
    
    .DESCRIPTION
        The MediaFile class provides a structured way to work with media files,
        including properties for file information and methods for media operations.
    #>
    
    # Properties
    [string]$Path
    [string]$Name
    [string]$Extension
    [long]$Size
    [datetime]$Created
    [datetime]$Modified
    [string]$MediaType
    [hashtable]$Metadata
    [string]$Codec
    [int]$Duration
    [int]$Bitrate
    [int]$Width
    [int]$Height
    [int]$FrameRate
    
    # Constructor
    MediaFile([string]$FilePath) {
        $this.Path = $FilePath
        $this.Name = [System.IO.Path]::GetFileName($FilePath)
        $this.Extension = [System.IO.Path]::GetExtension($FilePath)
        $this.MediaType = $this.GetMediaType()
        $this.Metadata = @{}
        
        if (Test-Path $FilePath) {
            $FileInfo = Get-Item $FilePath
            $this.Size = $FileInfo.Length
            $this.Created = $FileInfo.CreationTime
            $this.Modified = $FileInfo.LastWriteTime
            $this.LoadMetadata()
        }
    }
    
    # Methods
    [string] GetMediaType() {
        <#
        .SYNOPSIS
            Determines the media type based on file extension.
        #>
        $VideoExtensions = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v')
        $AudioExtensions = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a')
        $ImageExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp')
        
        if ($VideoExtensions -contains $this.Extension.ToLower()) {
            return 'Video'
        }
        elseif ($AudioExtensions -contains $this.Extension.ToLower()) {
            return 'Audio'
        }
        elseif ($ImageExtensions -contains $this.Extension.ToLower()) {
            return 'Image'
        }
        else {
            return 'Unknown'
        }
    }
    
    [void] LoadMetadata() {
        <#
        .SYNOPSIS
            Loads metadata from the media file.
        #>
        try {
            # This is a placeholder for actual metadata loading
            # In a real implementation, you might use FFmpeg, MediaInfo, or other tools
            Write-Message -Message "Loading metadata for $($this.Name)" -Level Verbose
            
            # Example metadata structure
            $this.Metadata = @{
                'Title' = $this.Name
                'Format' = $this.Extension.TrimStart('.')
                'Size' = $this.Size
                'Duration' = $this.Duration
                'Bitrate' = $this.Bitrate
            }
        }
        catch {
            Write-Message -Message "Failed to load metadata: $_" -Level Error
        }
    }
    
    [bool] IsValid() {
        <#
        .SYNOPSIS
            Checks if the media file is valid and accessible.
        #>
        return (Test-Path $this.Path) -and ($this.MediaType -ne 'Unknown')
    }
    
    [string] GetFormattedSize() {
        <#
        .SYNOPSIS
            Returns the file size in a human-readable format.
        #>
        $Sizes = @('B', 'KB', 'MB', 'GB', 'TB')
        $Index = 0
        $CalculatedSize = $this.Size
        
        while ($CalculatedSize -gt 1024 -and $Index -lt $Sizes.Length - 1) {
            $CalculatedSize = [math]::Round($CalculatedSize / 1024, 2)
            $Index++
        }
        
        return "{0:N2} {1}" -f $CalculatedSize, $Sizes[$Index]
    }
    
    [string] GetFormattedDuration() {
        <#
        .SYNOPSIS
            Returns the duration in a human-readable format.
        #>
        if ($this.Duration -eq 0) {
            return "Unknown"
        }
        
        $TimeSpan = [TimeSpan]::FromSeconds($this.Duration)
        return $TimeSpan.ToString("hh\:mm\:ss")
    }
    
    [string] ToString() {
        <#
        .SYNOPSIS
            Returns a string representation of the MediaFile object.
        #>
        return "[$($this.MediaType)] $($this.Name) ($($this.GetFormattedSize()))"
    }
} 