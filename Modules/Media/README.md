# Media Module

A PowerShell module for comprehensive media file management, analysis, and processing operations.

**NOTE: These tools are only intended for processing video files for which you a legal license to do so.**

## Overview

The Media module provides tools for:
- **Media analysis** - Extract detailed information from video, audio, and subtitle streams
- **FFmpeg integration** - Execute FFmpeg and FFprobe operations
- **Stream manipulation** - Add, export, and modify media streams
- **File operations** - Safe file renaming, copying, and organization
- **Plex integration** - File operations within Plex libraries
- **System monitoring** - Monitor system resources during media processing
- **Metadata extraction** - Extract and analyze media metadata
- **Format conversion** - Convert between different media formats

## Requirements

- PowerShell 7.4 or higher
- **FFmpeg** - For media processing operations
- **MKVToolNix** - For MKV file operations (optional)
- **Sufficient storage** - For media processing operations

## Installation

### Prerequisites

1. **Install FFmpeg**:
   ```powershell
   # Using Winget
   winget install Gyan.FFmpeg
   
   # Using Chocolatey (alternative)
   choco install ffmpeg
   ```

2. **Install MKVToolNix** (optional, for MKV operations):
   ```powershell
   # Using Winget
   winget install MKVToolNix.MKVToolNix
   
   # Using Chocolatey (alternative)
   choco install mkvtoolnix
   ```

3. **Verify installations**:
   ```powershell
   # Check FFmpeg
   ffmpeg -version
   
   # Check MKVToolNix (if installed)
   mkvmerge --version
   ```

### Module Installation

```powershell
# Clone the repository
git clone https://github.com/Dadstart/powershell-modules.git

# Import the Media module
Import-Module .\Modules\Media\MediaTools.psm1
```

## Functions

### Media Analysis

#### `Get-MediaStreams`
Get detailed information about all streams in a media file.

```powershell
# Get all streams from a video file
$streams = Get-MediaStreams -Path "C:\Videos\movie.mkv"

# Get specific stream types
$videoStreams = Get-MediaStreams -Path "C:\Videos\movie.mkv" -StreamType Video
$audioStreams = Get-MediaStreams -Path "C:\Videos\movie.mkv" -StreamType Audio
```

#### `Get-MediaStats`
Get comprehensive statistics about a media file.

```powershell
# Get media statistics
$stats = Get-MediaStats -Path "C:\Videos\movie.mkv"
$stats.Duration
$stats.Size
$stats.Bitrate
```

#### `Get-Bitrate`
Get bitrate information for media files.

```powershell
# Get overall bitrate
$bitrate = Get-Bitrate -Path "C:\Videos\movie.mkv"

# Get bitrates for multiple files
$bitrates = Get-Bitrates -Path "C:\Videos\*.mkv"
```

### Stream Operations

#### `Get-MediaStream`
Get information about a specific media stream.

```powershell
# Get video stream
$videoStream = Get-MediaStream -Path "C:\Videos\movie.mkv" -StreamType Video -Index 0

# Get audio stream
$audioStream = Get-MediaStream -Path "C:\Videos\movie.mkv" -StreamType Audio -Index 0
```

#### `Export-MediaStream`
Export a specific stream from a media file.

```powershell
# Export video stream
Export-MediaStream -Path "C:\Videos\movie.mkv" -StreamType Video -Index 0 -OutputPath "C:\Output\video.h264"

# Export audio stream
Export-MediaStream -Path "C:\Videos\movie.mkv" -StreamType Audio -Index 0 -OutputPath "C:\Output\audio.aac"
```

#### `Add-MediaStream`
Add a stream to an existing media file.

```powershell
# Add subtitle stream
Add-MediaStream -InputPath "C:\Videos\movie.mkv" -StreamPath "C:\Subtitles\subtitle.srt" -OutputPath "C:\Videos\movie_with_subs.mkv"
```

### Audio Operations

#### `Get-AudioStream`
Get detailed audio stream information.

```powershell
# Get audio stream details
$audioInfo = Get-AudioStream -Path "C:\Videos\movie.mkv" -Index 0
$audioInfo.Codec
$audioInfo.Channels
$audioInfo.SampleRate
```

#### `Export-AudioStream`
Extract audio streams from media files.

```powershell
# Export audio as MP3
Export-AudioStream -Path "C:\Videos\movie.mkv" -Index 0 -OutputPath "C:\Audio\audio.mp3"

# Export with specific settings
Export-AudioStream -Path "C:\Videos\movie.mkv" -Index 0 -OutputPath "C:\Audio\audio.aac" -Codec "aac" -Bitrate 192
```

#### `Get-AudioData`
Get comprehensive audio data analysis.

```powershell
# Get audio data
$audioData = Get-AudioData -Path "C:\Videos\movie.mkv" -Index 0
$audioData.PeakLevel
$audioData.AverageLevel
$audioData.DynamicRange
```

### Subtitle Operations

#### `Get-SubtitleStream`
Get subtitle stream information.

```powershell
# Get subtitle streams
$subtitleStreams = Get-SubtitleStream -Path "C:\Videos\movie.mkv"

# Get specific subtitle stream
$subtitleStream = Get-SubtitleStream -Path "C:\Videos\movie.mkv" -Index 0
```

#### `Export-SubtitleStream`
Extract subtitle streams from media files.

```powershell
# Export subtitle as SRT
Export-SubtitleStream -Path "C:\Videos\movie.mkv" -Index 0 -OutputPath "C:\Subtitles\subtitle.srt"

# Export as VTT
Export-SubtitleStream -Path "C:\Videos\movie.mkv" -Index 0 -OutputPath "C:\Subtitles\subtitle.vtt" -Format "vtt"
```

### Chapter Operations

#### `Get-ChapterInfo`
Get chapter information from media files.

```powershell
# Get chapter information
$chapters = Get-ChapterInfo -Path "C:\Videos\movie.mkv"

# Display chapters
$chapters | ForEach-Object { "$($_.Title) - $($_.StartTime)" }
```

#### `Export-Chapter`
Extract chapter information to external files.

```powershell
# Export chapters as XML
Export-Chapter -Path "C:\Videos\movie.mkv" -OutputPath "C:\Chapters\chapters.xml"

# Export as JSON
Export-Chapter -Path "C:\Videos\movie.mkv" -OutputPath "C:\Chapters\chapters.json" -Format "json"
```

### FFmpeg Operations

#### `Invoke-FFMpeg`
Execute FFmpeg commands with error handling.

```powershell
# Basic FFmpeg operation
Invoke-FFMpeg -Arguments "-i input.mkv -c:v libx264 -c:a aac output.mp4"

# With progress tracking
Invoke-FFMpeg -Arguments "-i input.mkv -c:v libx264 output.mp4" -ShowProgress
```

#### `Invoke-FFProbe`
Execute FFprobe commands to analyze media files.

```powershell
# Get media information
$info = Invoke-FFProbe -Arguments "-i movie.mkv -show_format -show_streams"

# Get specific stream info
$videoInfo = Invoke-FFProbe -Arguments "-i movie.mkv -select_streams v:0 -show_entries stream=codec_name,width,height"
```

#### `Get-FFMpegVersion`
Get FFmpeg version information.

```powershell
# Get FFmpeg version
$version = Get-FFMpegVersion
Write-Message "FFmpeg version: $version" -Type Info
```

### File Operations

#### `Invoke-SafeFileRename`
Safely rename files with conflict resolution.

```powershell
# Rename file safely
Invoke-SafeFileRename -Path "C:\Videos\movie.mkv" -NewName "Movie (2023).mkv"

# Rename with pattern
Invoke-SafeFileRename -Path "C:\Videos\*.mkv" -Pattern "movie" -Replacement "Movie"
```

#### `Invoke-VideoCopy`
Copy video files with progress tracking.

```powershell
# Copy video file
Invoke-VideoCopy -SourcePath "C:\Videos\movie.mkv" -DestinationPath "C:\Backup\movie.mkv"

# Copy with verification
Invoke-VideoCopy -SourcePath "C:\Videos\movie.mkv" -DestinationPath "C:\Backup\movie.mkv" -Verify
```

### Plex Integration

#### `Move-PlexFile`
Move files within Plex library structure.

```powershell
# Move file to new location
Move-PlexFile -SourcePath "C:\Plex\Movies\OldMovie.mkv" -DestinationPath "C:\Plex\Movies\NewMovie.mkv"

# Move with metadata preservation
Move-PlexFile -SourcePath "C:\Plex\Movies\OldMovie.mkv" -DestinationPath "C:\Plex\Movies\NewMovie.mkv" -PreserveMetadata
```

#### `Add-PlexFolder`
Add new folders to Plex library structure.

```powershell
# Add new folder
Add-PlexFolder -Path "C:\Plex\Movies\NewCategory"

# Add with permissions
Add-PlexFolder -Path "C:\Plex\Movies\NewCategory" -SetPermissions
```

#### `Remove-PlexEmptyFolder`
Remove empty folders from Plex library.

```powershell
# Remove empty folders
Remove-PlexEmptyFolder -Path "C:\Plex\Movies"

# Remove with confirmation
Remove-PlexEmptyFolder -Path "C:\Plex\Movies" -Confirm
```

### System Monitoring

#### `Get-SystemSnapshot`
Get current system resource usage.

```powershell
# Get system snapshot
$snapshot = Get-SystemSnapshot

# Display key metrics
Write-Message "CPU Usage: $($snapshot.CpuUsage)%" -Type Info
Write-Message "Memory Usage: $($snapshot.MemoryUsage)%" -Type Info
Write-Message "Disk Usage: $($snapshot.DiskUsage)%" -Type Info
```

#### `Start-SystemMonitoring`
Monitor system resources during long operations.

```powershell
# Start monitoring
$monitor = Start-SystemMonitoring -Interval 5

# Perform long operation
Invoke-FFMpeg -Arguments "-i large.mkv -c:v libx264 output.mp4"

# Stop monitoring
$monitor.Stop()
```

#### `Show-SystemSnapshot`
Display system snapshot in a formatted way.

```powershell
# Show current system state
Show-SystemSnapshot

# Show with specific metrics
Show-SystemSnapshot -IncludeDisk -IncludeNetwork
```

### Utility Functions

#### `Get-MediaExtension`
Get appropriate file extension for media formats.

```powershell
# Get extension for video codec
$extension = Get-MediaExtension -Codec "h264" -Type "Video"
# Returns: .mp4

# Get extension for audio codec
$extension = Get-MediaExtension -Codec "aac" -Type "Audio"
# Returns: .aac
```

#### `Get-EnhancedTitle`
Generate enhanced titles for media files.

```powershell
# Generate enhanced title
$title = Get-EnhancedTitle -Title "Movie Title" -Year 2023 -Quality "1080p"
# Returns: "Movie Title (2023) [1080p]"
```

#### `Get-EpisodeInfoFromFilename`
Extract episode information from filename.

```powershell
# Extract episode info
$episodeInfo = Get-EpisodeInfoFromFilename -Filename "Show.S01E05.Title.mkv"
$episodeInfo.Season
$episodeInfo.Episode
$episodeInfo.Title
```

## Classes

### `MediaStreamInfo`
Represents information about a media stream.

```powershell
$stream = [MediaStreamInfo]::new()
$stream.Codec = "h264"
$stream.Width = 1920
$stream.Height = 1080
```

### `MediaStreamInfoCollection`
Collection of media stream information.

```powershell
$collection = [MediaStreamInfoCollection]::new()
$collection.Add($stream1)
$collection.Add($stream2)
```

### `FFProbeResult`
Result from FFprobe operations.

```powershell
$result = [FFProbeResult]::new()
$result.Success = $true
$result.Output = $ffprobeOutput
```

### `ProcessResult`
Result from process operations.

```powershell
$result = [ProcessResult]::new()
$result.ExitCode = 0
$result.Output = $processOutput
```

## Examples

### Basic Media Analysis

```powershell
# Import the module
Import-Module .\Modules\Media\MediaTools.psm1

# Analyze a media file
$mediaPath = "C:\Videos\movie.mkv"

Write-Message "Analyzing media file: $mediaPath" -Type Info

# Get basic stats
$stats = Get-MediaStats -Path $mediaPath
Write-Message "Duration: $($stats.Duration)" -Type Info
Write-Message "Size: $($stats.Size)" -Type Info

# Get all streams
$streams = Get-MediaStreams -Path $mediaPath
Write-Message "Found $($streams.Count) streams" -Type Info

# Display stream information
foreach ($stream in $streams) {
    Write-Message "Stream $($stream.Index): $($stream.Codec) ($($stream.Type))" -Type Info
}
```

### Audio Stream Processing

```powershell
# Function to extract all audio streams
function Export-AllAudioStreams {
    param(
        [string]$InputPath,
        [string]$OutputDirectory
    )
    
    # Get all audio streams
    $audioStreams = Get-MediaStreams -Path $InputPath -StreamType Audio
    
    Write-Message "Found $($audioStreams.Count) audio streams" -Type Info
    
    foreach ($stream in $audioStreams) {
        $outputPath = Join-Path $OutputDirectory "audio_$($stream.Index).aac"
        
        Write-Message "Exporting audio stream $($stream.Index)" -Type Processing
        
        Export-AudioStream -Path $InputPath -Index $stream.Index -OutputPath $outputPath
        
        Write-Message "Exported: $outputPath" -Type Success
    }
}

# Use the function
Export-AllAudioStreams -InputPath "C:\Videos\movie.mkv" -OutputDirectory "C:\Audio"
```

### Batch Media Processing

```powershell
# Process all MKV files in a directory
$inputDir = "C:\Videos\Raw"
$outputDir = "C:\Videos\Processed"

# Get all MKV files
$mkvFiles = Get-ChildItem -Path $inputDir -Filter "*.mkv" -Recurse

Write-Message "Found $($mkvFiles.Count) MKV files to process" -Type Info

foreach ($file in $mkvFiles) {
    Write-Message "Processing: $($file.Name)" -Type Processing
    
    # Get media stats
    $stats = Get-MediaStats -Path $file.FullName
    
    # Create output path
    $outputPath = Join-Path $outputDir $file.Name
    
    # Copy with verification
    Invoke-VideoCopy -SourcePath $file.FullName -DestinationPath $outputPath -Verify
    
    Write-Message "Completed: $($file.Name)" -Type Success
}
```

### System Monitoring During Processing

```powershell
# Monitor system during long operation
function Process-WithMonitoring {
    param(
        [string]$InputPath,
        [string]$OutputPath
    )
    
    # Start system monitoring
    $monitor = Start-SystemMonitoring -Interval 10
    
    try {
        Write-Message "Starting media processing" -Type Processing
        
        # Perform the operation
        Invoke-FFMpeg -Arguments "-i `"$InputPath`" -c:v libx264 -c:a aac `"$OutputPath`"" -ShowProgress
        
        Write-Message "Processing completed" -Type Success
    }
    finally {
        # Stop monitoring
        $monitor.Stop()
        
        # Show final snapshot
        Show-SystemSnapshot
    }
}

# Use the function
Process-WithMonitoring -InputPath "C:\Videos\large.mkv" -OutputPath "C:\Videos\compressed.mp4"
```

### Plex Library Management

```powershell
# Function to organize Plex library
function Organize-PlexLibrary {
    param(
        [string]$LibraryPath,
        [string]$Pattern,
        [string]$NewCategory
    )
    
    # Get files matching pattern
    $files = Get-ChildItem -Path $LibraryPath -Filter $Pattern -Recurse
    
    Write-Message "Found $($files.Count) files to organize" -Type Info
    
    foreach ($file in $files) {
        # Create new category folder
        $categoryPath = Join-Path $LibraryPath $NewCategory
        Add-PlexFolder -Path $categoryPath
        
        # Move file to new category
        $newPath = Join-Path $categoryPath $file.Name
        Move-PlexFile -SourcePath $file.FullName -DestinationPath $newPath
        
        Write-Message "Moved: $($file.Name)" -Type Success
    }
    
    # Remove empty folders
    Remove-PlexEmptyFolder -Path $LibraryPath
}

# Use the function
Organize-PlexLibrary -LibraryPath "C:\Plex\Movies" -Pattern "*4K*" -NewCategory "4K Movies"
```

## Configuration

### FFmpeg Settings

Configure FFmpeg parameters:

```powershell
# Common video codecs
$videoCodecs = @{
    "H.264" = "libx264"
    "H.265" = "libx265"
    "VP9" = "libvpx-vp9"
}

# Common audio codecs
$audioCodecs = @{
    "AAC" = "aac"
    "MP3" = "mp3"
    "AC3" = "ac3"
}
```

### Quality Settings

Common quality presets:

```powershell
$qualityPresets = @{
    "Low" = @{ CRF = 28; AudioBitrate = 128 }
    "Medium" = @{ CRF = 23; AudioBitrate = 160 }
    "High" = @{ CRF = 18; AudioBitrate = 192 }
    "Very High" = @{ CRF = 16; AudioBitrate = 256 }
}
```

## Error Handling

All functions include comprehensive error handling and will provide detailed error messages when operations fail.

## Performance

- **Multi-threading** support for faster processing
- **Hardware acceleration** when available
- **Progress tracking** for long operations
- **Memory management** for large files

## Integration

The Media module integrates with:
- **Shared module** - For consistent logging and error handling
- **Plex module** - For library management
- **Rip module** - For media processing workflows

## Best Practices

### File Management

- Always use safe file operations
- Verify file integrity after operations
- Keep backups of important files
- Use appropriate file naming conventions

### Performance

- Monitor system resources during long operations
- Use hardware acceleration when available
- Process files in batches for efficiency
- Clean up temporary files after processing

### Quality Settings

- Choose appropriate quality settings for your needs
- Test with small samples before batch processing
- Consider storage space vs. quality trade-offs

## Contributing

When adding new functions to the Media module:

1. Follow the existing naming conventions
2. Include comprehensive help documentation
3. Add appropriate error handling using `Invoke-WithErrorHandling`
4. Write unit tests for new functions
5. Update this README with new function documentation

## License

This module is part of the PowerShell modules collection. See the main LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: <https://github.com/Dadstart/powershell-modules/issues>
- Documentation: See individual function help with `Get-Help <FunctionName>`
