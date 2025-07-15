# VideoFunctions PowerShell Module

A PowerShell module for video file processing and Plex folder management. This module provides functions for working with FFmpeg, MKV files, and Plex media organization.

## Features

- **FFmpeg Integration**: Functions for working with FFmpeg and FFprobe
- **MKV Processing**: Extract audio and subtitle tracks from MKV files
- **Media Analysis**: Analyze media streams and properties
- **Plex Organization**: Automate Plex media folder structure and file organization

## Installation

### Prerequisites

- PowerShell 5.1 or higher
- FFmpeg (for FFmpeg-related functions)
- MKVToolNix (for MKV processing functions)

### Easiest No-Fuss Install

Run the quick install script `QuickInstall.ps1`. This removes any existing installation and installs the current version.

### Install

Run the install script `Install.ps1`

### Uninstall

Run the uninstall script `Uinstall.ps1`

## Module Structure

The module follows PowerShell best practices with organized function structure:

```
VideoFunctions/
├── VideoFunctions.psd1          # Module manifest
├── VideoFunctions.psm1          # Root module file
├── Install.ps1                  # Install script
├── QuickInstall.ps1             # Quick install script
├── Uninstall.ps1                # Uninstall script
├── Public/                      # Public functions (exported)
│   ├── Get-FFMpegVersion.ps1
│   ├── Invoke-FFProbe.ps1
│   ├── Get-MkvTrack.ps1
│   ├── Get-MkvTracks.ps1
│   ├── Get-MkvTrackAll.ps1
│   ├── Get-MediaStreams.ps1
│   ├── Add-PlexFolders.ps1
│   ├── Move-PlexFiles.ps1
│   ├── Remove-PlexEmptyFolders.ps1
│   └── Invoke-PlexFileOperations.ps1
├── Private/                     # Private helper functions
│   ├── Test-FFMpegInstalled.ps1
│   ├── Get-FileFromPath.ps1
│   └── Invoke-Process.ps1
└── README.md
```

## Available Functions

### FFmpeg Functions

#### `Get-FFMpegVersion`

Retrieves the version of FFmpeg installed on the system.

```powershell
Get-FFMpegVersion
```

#### `Invoke-FFProbe`

Runs FFprobe with specified arguments and returns parsed JSON output.

```powershell
Invoke-FFProbe '-show_streams', 'video.mp4'
```

### MKV Functions

#### `Get-MkvTrack`

Extracts a single track from an MKV file.

```powershell
Get-MkvTrack 'Movie.mkv' 2 'en.sdh.sup'
```

#### `Get-MkvTracks`

Extracts multiple tracks from an MKV file.

```powershell
Get-MkvTracks 'Movie.mkv' (2,3) 'ac3'
```

#### `Get-MkvTrackAll`

Extracts the same track from multiple MKV files.

```powershell
Get-MkvTrackAll ('Movie.mkv','Film.mkv') 2 'en.sdh.sup'
```

### Media Analysis Functions

#### `Get-MediaStreams`

Retrieves and filters media streams from a file.

```powershell
# Get all audio streams
Get-MediaStreams 'video.mp4' -Type Audio

# Get English subtitle streams
Get-MediaStreams 'video.mp4' -Type Subtitle -Language 'eng'
```

### Plex Functions

#### `Add-PlexFolders`

Creates the standard Plex bonus content folder structure.

```powershell
Add-PlexFolders 'C:\plex\movies\My Movie'
```

#### `Move-PlexFiles`

Moves bonus content files to appropriate Plex folders.

```powershell
Move-PlexFiles 'C:\plex\movies\My Movie'
```

#### `Remove-PlexEmptyFolders`

Removes empty Plex bonus content folders.

```powershell
Remove-PlexEmptyFolders 'C:\plex\movies\My Movie'
```

#### `Invoke-PlexFileOperations`

Performs all Plex organization operations in sequence.

```powershell
Invoke-PlexFileOperations 'C:\plex\movies\My Movie'
```

## Plex Folder Structure

The module creates the following standard Plex bonus content folders:

- **Behind The Scenes** - Files with `-behindthescenes` suffix
- **Deleted Scenes** - Files with `-deleted` suffix
- **Featurettes** - Files with `-featurette` suffix
- **Interviews** - Files with `-interview` suffix
- **Scenes** - Files with `-scene` suffix
- **Shorts** - Files with `-short` suffix
- **Trailers** - Files with `-trailer` suffix
- **Other** - Files with `-other` suffix

## Examples

### Complete Plex Organization Workflow

```powershell
# Import the module
Import-Module VideoFunctions

# Organize a movie directory
Invoke-PlexFileOperations 'C:\plex\movies\The Matrix (1999)'
```

### MKV Track Extraction Workflow

```powershell
# Extract English subtitle track
Get-MkvTrack 'Movie.mkv' 2 'en.sdh.sup'

# Extract multiple audio tracks
Get-MkvTracks 'Movie.mkv' (1,2,3) 'ac3'
```

### Media Analysis

```powershell
# Get all streams in a video file
$streams = Get-MediaStreams 'video.mp4'

# Get only audio streams
$audioStreams = Get-MediaStreams 'video.mp4' -Type Audio

# Get English subtitle streams
$englishSubtitles = Get-MediaStreams 'video.mp4' -Type Subtitle -Language 'eng'
```

## Error Handling

The module includes comprehensive error handling:

- FFmpeg dependency checking
- File existence validation
- Process execution error handling
- Detailed error messages and logging

## Installation Scripts

### Install-VideoFunctions.ps1

The installation script provides the following features:

- **Automatic Detection**: Detects PowerShell version and edition
- **Scope Support**: Install for current user or all users
- **Validation**: Verifies module structure before installation
- **Testing**: Tests module import after installation
- **Error Handling**: Comprehensive error handling and logging
- **WhatIf Support**: Preview installation without executing

**Parameters:**

- `-Scope`: 'CurrentUser' (default) or 'AllUsers'
- `-Force`: Overwrite existing installation
- `-WhatIf`: Preview installation
- `-Confirm`: Prompt for confirmation

### Uninstall-VideoFunctions.ps1

The uninstallation script provides the following features:

- **Complete Removal**: Removes module from all locations
- **Scope Support**: Remove from specific scopes
- **Memory Cleanup**: Removes module from memory if loaded
- **Verification**: Confirms complete removal
- **Safety**: Prompts for confirmation by default

**Parameters:**

- `-Scope`: 'CurrentUser', 'AllUsers', or 'All' (default)
- `-Force`: Skip confirmation prompts
- `-WhatIf`: Preview uninstallation
- `-Confirm`: Prompt for confirmation

## Contributing

[Contributing](/CONTRIBUTING.md)

## License

[Apache License](/LICENSE)

## Version History

[Version History](VERSION.md)
