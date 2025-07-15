# DVD Module

A PowerShell module for DVD processing workflows including HandBrake conversion, remuxing, and bonus content processing.

## Overview

The DVD module provides a comprehensive set of functions for processing DVD content through various stages of conversion and optimization. It integrates with the Video module to provide advanced video processing capabilities.

## Features

- **DVD Processing**: Complete workflow for processing DVD content with chapter and caption extraction
- **HandBrake Conversion**: Video conversion with audio stream management and metadata updates
- **Remux Processing**: Combining original video with HandBrake audio streams
- **Bonus Content Processing**: Specialized processing for bonus content with audio type detection

## Installation

The DVD module requires the Video module to be installed. Install both modules using:

```powershell
# Install the Video module first
Install-Module -Name Video -Force

# Install the DVD module
Install-Module -Name DVD -Force
```

## Functions

### Invoke-DvdProcessing

Processes DVD content with chapter extraction, caption extraction, and directory structure creation.

```powershell
Invoke-DvdProcessing -Title "MyShow" -Path "D:\DVD1,D:\DVD2" -FilePatterns "*.vob","*.m2ts" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/myshow"
```

**Parameters:**
- `Title`: The title of the DVD content to process
- `Path`: The source directories containing the DVD content
- `FilePatterns`: Array of file patterns to match for processing
- `Season`: The season number for the content
- `TvDbSeriesUrl`: The TVDb series URL for metadata retrieval
- `SkipChapterExtraction`: Skip chapter extraction phase
- `SkipCaptionExtraction`: Skip caption extraction phase

### Invoke-HandbrakeConversion

Converts video files using HandBrake with audio stream management and metadata updates.

```powershell
Invoke-HandbrakeConversion -Path "C:\Input" -Destination "C:\Output" -Language "eng"
```

**Parameters:**
- `Path`: The directory containing input video files to process
- `Destination`: The directory where converted files will be saved
- `Language`: The language code for audio streams to process (default: 'eng')

### Invoke-RemuxProcessing

Processes remux operations by combining original video with HandBrake audio streams.

```powershell
Invoke-RemuxProcessing -Path "C:\Original" -HandbrakeDirectory "C:\HandBrake" -Destination "C:\Remuxed"
```

**Parameters:**
- `Path`: The directory containing original video files to process
- `Destination`: The directory where converted files will be saved

### Invoke-BonusContentProcessing

Processes bonus content by detecting audio stream types and converting them with appropriate settings.

```powershell
Invoke-BonusContentProcessing -Path "C:\Bonus" -Destination "C:\Converted" -Language "eng"
```

**Parameters:**
- `OriginalDirectory`: The directory containing original video files to process
- `OutputDirectory`: The directory where converted files will be saved
- `Language`: The language code for audio streams to process (default: 'eng')

## Usage Examples

### Complete DVD Processing Workflow

```powershell
# 1. Process DVD content
Invoke-DvdProcessing -Title "MyShow" -Path "D:\DVD1" -FilePatterns "*.vob" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/myshow"

# 2. Convert with HandBrake
Invoke-HandbrakeConversion -Path ".\MyShow\Season 01" -Destination ".\MyShow\Season 01\HandBrake"

# 3. Process remux
Invoke-RemuxProcessing -Path ".\MyShow\Season 01" -HandbrakeDirectory ".\MyShow\Season 01\HandBrake" -Destination ".\MyShow\Season 01\Remux"

# 4. Process bonus content
Invoke-BonusContentProcessing -Path ".\MyShow\Season 01\Bonus" -Destination ".\MyShow\Season 01\Bonus\Converted"
```

### Pipeline Usage

```powershell
# Process multiple directories
Get-ChildItem "C:\Videos" -Directory | Invoke-HandbrakeConversion -Destination "C:\Converted"

# Process bonus content for multiple shows
Get-ChildItem "C:\Shows" -Directory | ForEach-Object { 
    $bonusPath = Join-Path $_.FullName "Bonus"
    if (Test-Path $bonusPath) {
        Invoke-BonusContentProcessing -Path $bonusPath -Destination (Join-Path $_.FullName "Bonus\Converted")
    }
}
```

## Requirements

- PowerShell 5.1 or later
- Video module
- HandBrake CLI
- FFmpeg
- TVDb API access (for metadata retrieval)

## Audio Stream Types

The module supports the following audio stream types:
- **Surround 5.1**: 5.1 channel surround sound
- **Stereo**: 2-channel stereo audio
- **Mono**: Single channel audio

Each type is processed with appropriate HandBrake settings:
- Surround 5.1: 384 kbps, 5.1 mixdown
- Stereo: 160 kbps, stereo mixdown
- Mono: 80 kbps, mono mixdown

## Error Handling

The module includes comprehensive error handling:
- Files with multiple audio streams of the same language are skipped
- Unknown audio stream types are logged and skipped
- Missing directories are detected and reported
- Temporary files are cleaned up automatically

## Logging and Verbose Output

All functions support verbose output for detailed logging:

```powershell
Invoke-HandbrakeConversion -Path "C:\Input" -Destination "C:\Output" -Verbose
```

## Contributing

Contributions are welcome! Please ensure all functions follow PowerShell best practices:
- Use `[CmdletBinding()]` for all functions
- Include comprehensive help documentation
- Use proper parameter validation
- Follow the Verb-Noun naming convention
- Include error handling and logging

## License

© 2025 Dadstart. All rights reserved.

## Support

For issues and questions, please refer to the project documentation or create an issue in the repository. 
