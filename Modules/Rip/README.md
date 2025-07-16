# Rip Module

A PowerShell module for legal media ripping and extraction tools.

**NOTE: These tools are only intended for ripping and processing DVD and Blu-ray video files for which you a legal license to do so.**

## Overview

The Rip module provides tools for:
- **DVD/Blu-ray ripping** - Extract content from legally license optical media
- **Video conversion** - Convert between different video formats
- **HandBrake integration** - Automated video encoding workflows
- **Remux processing** - Stream extraction and remuxing
- **Season processing** - Batch processing of TV series
- **Bonus content handling** - Extract and process bonus features

## Requirements

- PowerShell 7.4 or higher
- **HandBrake CLI** - For video encoding operations
- **FFmpeg** - For media processing (via Media module)
- **Optical drive** - For DVD/Blu-ray ripping
- **Sufficient storage** - For temporary and output files

## Installation

### Prerequisites

1. **Install HandBrake CLI**:
   ```powershell
   # Using Winget
   winget install HandBrake.HandBrake
   
   # Using Chocolatey (alternative)
   choco install handbrake-cli
   
   # Download from official site
   # https://handbrake.fr/downloads2.php
   ```

2. **Install FFmpeg** (if not already installed):
   ```powershell
   # Using Winget
   winget install Gyan.FFmpeg
   
   # Using Chocolatey (alternative)
   choco install ffmpeg
   ```

3. **Verify installations**:
   ```powershell
   # Check HandBrake
   HandBrakeCLI --version
   
   # Check FFmpeg
   ffmpeg -version
   ```

### Module Installation

```powershell
# Clone the repository
git clone https://github.com/Dadstart/powershell-modules.git

# Import the Rip module
Import-Module .\Modules\Rip\RipTools.psm1
```

## Functions

### DVD Processing

#### `Invoke-DvdProcessing`
Process DVDs with automated ripping and conversion workflows.

```powershell
# Process a DVD with default settings
Invoke-DvdProcessing -DriveLetter "D:" -OutputPath "C:\Rips\Movie"

# Process with custom settings
Invoke-DvdProcessing -DriveLetter "D:" -OutputPath "C:\Rips\Movie" -Quality "High" -AudioTracks @(0,1)
```

### Video Conversion

#### `Convert-VideoFiles`
Convert video files between different formats using HandBrake.

```powershell
# Convert a single file
Convert-VideoFiles -InputPath "C:\Videos\input.mkv" -OutputPath "C:\Videos\output.mp4"

# Convert multiple files
$files = Get-ChildItem "C:\Videos" -Filter "*.mkv"
Convert-VideoFiles -InputFiles $files -OutputDirectory "C:\Converted" -Preset "Fast 1080p30"
```

#### `Invoke-HandbrakeConversion`
Execute HandBrake conversions with custom parameters.

```powershell
# Convert with specific settings
Invoke-HandbrakeConversion -InputPath "input.mkv" -OutputPath "output.mp4" -Preset "Fast 1080p30"

# Convert with custom parameters
$params = @{
    InputPath = "input.mkv"
    OutputPath = "output.mp4"
    VideoCodec = "H.264"
    AudioCodec = "AAC"
    Quality = 20
}
Invoke-HandbrakeConversion @params
```

### Remux Processing

#### `Invoke-RemuxProcessing`
Extract and remux streams from media files.

```powershell
# Remux with specific streams
Invoke-RemuxProcessing -InputPath "C:\Videos\movie.mkv" -OutputPath "C:\Videos\remuxed.mkv" -VideoStream 0 -AudioStreams @(0,1)

# Remux with subtitle extraction
Invoke-RemuxProcessing -InputPath "C:\Videos\movie.mkv" -OutputPath "C:\Videos\remuxed.mkv" -ExtractSubtitles
```

### Season Processing

#### `Invoke-SeasonScan`
Process entire TV seasons with automated workflows.

```powershell
# Process a season directory
Invoke-SeasonScan -SeasonPath "C:\TV\Show\Season 1" -OutputPath "C:\Processed\Show\Season 1"

# Process with specific settings
Invoke-SeasonScan -SeasonPath "C:\TV\Show\Season 1" -OutputPath "C:\Processed\Show\Season 1" -Quality "High" -AudioTracks @(0)
```

### Bonus Content

#### `Invoke-BonusContentProcessing`
Extract and process bonus content from DVDs/Blu-rays.

```powershell
# Process bonus content
Invoke-BonusContentProcessing -DriveLetter "D:" -OutputPath "C:\Bonus\Movie" -ExtractAll

# Process specific bonus features
Invoke-BonusContentProcessing -DriveLetter "D:" -OutputPath "C:\Bonus\Movie" -Features @("Behind the Scenes", "Deleted Scenes")
```

## Examples

### Basic DVD Ripping

```powershell
# Import the module
Import-Module .\Modules\Rip\RipTools.psm1

# Check available drives
Get-WmiObject -Class Win32_CDROMDrive | Select-Object Drive, MediaType

# Process DVD
$dvdDrive = "D:"
$outputPath = "C:\Rips\MyMovie"

if (Test-Path $dvdDrive) {
    Write-Message "Processing DVD from drive $dvdDrive" -Type Processing
    
    Invoke-DvdProcessing -DriveLetter $dvdDrive -OutputPath $outputPath
    
    Write-Message "DVD processing completed" -Type Success
} else {
    Write-Message "No DVD found in drive $dvdDrive" -Type Error
}
```

### Batch Video Conversion

```powershell
# Convert all MKV files in a directory
$inputDir = "C:\Videos\Raw"
$outputDir = "C:\Videos\Converted"

# Get all MKV files
$mkvFiles = Get-ChildItem -Path $inputDir -Filter "*.mkv" -Recurse

Write-Message "Found $($mkvFiles.Count) MKV files to convert" -Type Info

# Convert each file
foreach ($file in $mkvFiles) {
    $outputPath = Join-Path $outputDir $file.BaseName + ".mp4"
    
    Write-Message "Converting $($file.Name)" -Type Processing
    
    Convert-VideoFiles -InputPath $file.FullName -OutputPath $outputPath -Preset "Fast 1080p30"
    
    Write-Message "Completed: $($file.Name)" -Type Success
}
```

### Season Processing Workflow

```powershell
# Function to process an entire TV series
function Process-TvSeries {
    param(
        [string]$SeriesPath,
        [string]$OutputPath,
        [string]$Quality = "High"
    )
    
    # Get all season directories
    $seasons = Get-ChildItem -Path $SeriesPath -Directory | Where-Object { $_.Name -like "Season*" }
    
    Write-Message "Found $($seasons.Count) seasons to process" -Type Info
    
    foreach ($season in $seasons) {
        $seasonOutput = Join-Path $OutputPath $season.Name
        
        Write-Message "Processing $($season.Name)" -Type Processing
        
        # Process the season
        Invoke-SeasonScan -SeasonPath $season.FullName -OutputPath $seasonOutput -Quality $Quality
        
        Write-Message "Completed: $($season.Name)" -Type Success
    }
}

# Use the function
Process-TvSeries -SeriesPath "C:\TV\Breaking Bad" -OutputPath "C:\Processed\Breaking Bad"
```

### Advanced HandBrake Conversion

```powershell
# Custom conversion with specific settings
$conversionParams = @{
    InputPath = "C:\Videos\input.mkv"
    OutputPath = "C:\Videos\output.mp4"
    VideoCodec = "H.264"
    AudioCodec = "AAC"
    Quality = 18  # High quality
    AudioBitrate = 160
    SubtitleBurn = $true
    Deinterlace = $true
}

Write-Message "Starting custom conversion" -Type Processing

Invoke-HandbrakeConversion @conversionParams

Write-Message "Custom conversion completed" -Type Success
```

### Remux with Stream Selection

```powershell
# Remux with specific audio tracks
$remuxParams = @{
    InputPath = "C:\Videos\movie.mkv"
    OutputPath = "C:\Videos\movie_english.mkv"
    VideoStream = 0
    AudioStreams = @(0)  # English audio only
    SubtitleStreams = @(0, 1)  # English and Spanish subtitles
}

Write-Message "Remuxing with selected streams" -Type Processing

Invoke-RemuxProcessing @remuxParams

Write-Message "Remux completed" -Type Success
```

### Bonus Content Extraction

```powershell
# Extract bonus content from DVD
$dvdDrive = "D:"
$bonusPath = "C:\Bonus\Movie"

Write-Message "Extracting bonus content" -Type Processing

# Extract all bonus features
Invoke-BonusContentProcessing -DriveLetter $dvdDrive -OutputPath $bonusPath -ExtractAll

# List extracted content
$bonusFiles = Get-ChildItem -Path $bonusPath -Recurse -File
Write-Message "Extracted $($bonusFiles.Count) bonus files" -Type Success
```

## Configuration

### HandBrake Settings

Configure HandBrake parameters:

```powershell
# Common presets
$presets = @(
    "Fast 1080p30",
    "Fast 720p30", 
    "HQ 1080p30 Surround",
    "Super HQ 1080p30 Surround"
)

# Quality settings (lower = higher quality)
$qualitySettings = @{
    "Low" = 25
    "Medium" = 20
    "High" = 18
    "Very High" = 16
}
```

### Output Formats

Supported output formats:
- **MP4** - H.264 video, AAC audio
- **MKV** - H.264/H.265 video, various audio codecs
- **AVI** - Legacy format support
- **WebM** - Web-optimized format

## Error Handling

All functions include comprehensive error handling and will provide detailed error messages when operations fail.

## Performance

- **Multi-threading** support for faster processing
- **Hardware acceleration** when available
- **Progress tracking** for long operations
- **Resume capability** for interrupted operations

## Integration

The Rip module integrates with:
- **Media module** - For media analysis and processing
- **Shared module** - For consistent logging and error handling
- **Plex module** - For direct library integration

## Best Practices

### Storage Management

- Ensure sufficient free space (typically 2-3x source size)
- Use fast storage for temporary files
- Clean up temporary files after processing

### Quality Settings

- Use appropriate quality settings for your needs
- Test with small samples before batch processing
- Consider storage space vs. quality trade-offs

### File Organization

- Use consistent naming conventions
- Organize output by series/movie
- Keep source files for re-processing if needed

## Contributing

When adding new functions to the Rip module:

1. Follow the existing naming conventions
2. Include comprehensive help documentation
3. Add appropriate error handling using `Invoke-WithErrorHandling`
4. Write unit tests for new functions
5. Update this README with new function documentation

## License

This module is part of the PowerShell modules collection. See the main LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/Dadstart/powershell-modules/issues
- Documentation: See individual function help with `Get-Help <FunctionName>`
