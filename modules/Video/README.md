# Video PowerShell Module

A comprehensive PowerShell module for video processing, conversion, and management including HandBrake integration, chapter extraction, and TVDb episode information retrieval.

## Features

- **Video Conversion**: Convert MKV files using HandBrake with custom presets
- **Chapter Extraction**: Extract specific chapters from video files
- **TVDb Integration**: Automatically retrieve episode information from TVDb
- **Audio Analysis**: Analyze and manage audio streams in video files
- **Safe File Renaming**: Rename files safely with conflict resolution
- **Constant Frame Rate Conversion**: Convert variable frame rate videos to constant frame rate
- **DVD/Blu-ray Processing**: Complete workflows for processing DVD and Blu-ray rips

## Installation

### Method 1: Install from Local Directory

1. Clone or download this repository
2. Navigate to the video directory
3. Import the module:

```powershell
Import-Module .\Video.psd1
```

### Method 2: Install to User Modules Directory

```powershell
# Copy the module to your user modules directory
$userModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Video"
New-Item -ItemType Directory -Path $userModulePath -Force
Copy-Item -Path ".\*" -Destination $userModulePath -Recurse

# Import the module
Import-Module Video
```

## Prerequisites

- **PowerShell 5.1 or later**
- **HandBrake CLI**: Required for video conversion
- **ffmpeg**: Required for chapter extraction and frame rate conversion
- **VideoUtility Module**: Required for caption extraction (optional)

## Quick Start

### Basic Video Conversion

```powershell
# Convert MKV files to MP4 using a HandBrake preset
Convert-VideoFiles -InputFolder "C:\Videos\Input" -OutputFolder "C:\Videos\Output" -PresetFile "C:\HandBrake\presets\Fast 1080p30.json"
```

### Process DVD/Blu-ray Rips

```powershell
# Process DVD rips with chapter extraction and TVDb integration
Invoke-ProcessDvd -Title "Breaking Bad" -Folders "C:\Rips\Breaking Bad S1" -Destination "C:\Shows" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/breaking-bad" -FilePatterns "C4_*","B3_*" -ExtractChapter -ExtractCaptions
```

### Safe File Renaming

```powershell
# Rename files safely with conflict resolution
Invoke-SafeFileRename -FileMappings @{"old_name" = "new_name"; "movie1" = "movie_renamed"} -WorkingDirectory "C:\Videos"
```

## Available Functions

### Video Conversion
- `Convert-VideoFiles` - Convert MKV files using HandBrake
- `Convert-ToConstantFrameRate` - Convert variable frame rate videos to constant frame rate

### Chapter Management
- `Get-ChapterInfo` - Get chapter information from video files
- `Extract-Chapter` - Extract specific chapters from video files

### Audio Analysis
- `Show-AudioData` - Display audio stream information
- `Get-AudioData` - Get audio stream data as objects
- `Get-MultipleAudioStreams` - Find files with multiple audio streams
- `Show-MultipleAudioStreams` - Display multiple audio stream information

### File Management
- `Invoke-SafeFileRename` - Safely rename files with conflict resolution
- `Invoke-ProcessDvd` - Complete DVD/Blu-ray processing workflow

### TVDb Integration
- `Get-TvDbEpisodeInfo` - Retrieve episode information from TVDb
- `Get-TvDbEpisodeIds` - Get episode IDs from TVDb (legacy function)

### Utility Functions
- `Invoke-CheckedCommand` - Execute commands with error checking
- `Resolve-InputPath` - Resolve and validate input paths
- `Get-AudioMetadataMap` - Get audio metadata mapping for ffmpeg
- `Get-EpisodeInfoFromFilename` - Extract episode info from filename
- `Get-EnhancedTitle` - Generate enhanced titles with episode information

## Examples

### Convert Videos with Parallel Processing

```powershell
Convert-VideoFiles -InputFolder "C:\Videos\Input" -OutputFolder "C:\Videos\Output" -PresetFile "C:\HandBrake\presets\Fast 1080p30.json" -Parallel 4 -Force -Verbose
```

### Extract Chapter 2 from All Videos

```powershell
Get-ChildItem "C:\Videos" -Filter "*.mkv" | ForEach-Object {
    $chapter = Get-ChapterInfo -InputFile $_.FullName -ChapterNumber 2
    if ($chapter) {
        $outputFile = Join-Path $_.DirectoryName "$($_.BaseName)_chapter2.mkv"
        Extract-Chapter -InputFile $_.FullName -Chapter $chapter -OutputFile $outputFile -MaxDuration 30
    }
}
```

### Analyze Audio Streams

```powershell
# Find files with multiple English audio streams
$multiAudio = Get-MultipleAudioStreams -Language "eng"
$multiAudio | ForEach-Object {
    "File: $($_.Name) has $($_.Group.Count) English audio streams"
}
```

### Process TV Show with TVDb Integration

```powershell
Invoke-ProcessDvd -Title "The Office" -Folders "C:\Rips\The Office S1" -Destination "C:\Shows" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/the-office-us" -FilePatterns "C4_*","B3_*","B4_*","D4_*" -ExtractChapter -ChapterNumber 2 -ChapterDuration 60 -ExtractCaptions -WhatIf
```

## Error Handling

The module follows PowerShell best practices for error handling:

- Uses `-ErrorAction` parameter support
- Implements `SupportsShouldProcess` for `-WhatIf` and `-Confirm`
- Provides verbose output with `-Verbose` parameter
- Uses proper error streams and information streams

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This module is provided as-is for educational and personal use.

## Support

For issues and questions, please check the PowerShell best practices documentation or create an issue in the repository. 