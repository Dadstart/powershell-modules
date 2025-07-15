# Plex Module

PowerShell utilities for managing and interacting with Plex Media Server.

## Overview

The Plex module provides a comprehensive set of PowerShell functions for interacting with Plex Media Server through its REST API. This module allows you to retrieve server information, manage libraries, and interact with media content programmatically.

## Features

- **Server Management**: Get server information and test connectivity
- **Library Operations**: Retrieve libraries and their contents
- **Media Information**: Get detailed information about media items
- **Library Scanning**: Trigger library scans to detect new content
- **Error Handling**: Comprehensive error handling and logging
- **Validation**: Built-in parameter validation for Plex-specific data

## Functions

### Public Functions

- **Get-PlexCredential**: Retrieve or prompt for Plex authentication credentials
- **Test-PlexConnection**: Test connectivity to a Plex server
- **Get-PlexServerInfo**: Retrieve detailed server information
- **Get-PlexLibraries**: Get all libraries from a Plex server
- **Get-PlexLibraryItems**: Retrieve items from a specific library
- **Get-PlexMediaInfo**: Get detailed information about a media item
- **Invoke-PlexLibraryScan**: Trigger a library scan

### Private Functions

- **Invoke-PlexApiRequest**: Internal function for making API requests with automatic token handling
- **Get-ValidationAttributes**: Plex-specific validation patterns
- **Set-DefaultParameters**: Set default parameters for the module

## Installation

The Plex module is included in the main repository and can be installed using the `install-modules.ps1` script:

```powershell
.\utilities\install-modules.ps1
```

## Usage Examples

### Authentication and Credentials

```powershell
# Get credentials interactively (uses default localhost server)
$credentials = Get-PlexCredential

# Get credentials with specific server URL
$credentials = Get-PlexCredential -ServerUrl "http://192.168.1.100:32400"

# Use credentials with other functions
$libraries = Get-PlexLibraries -Credential $credentials
```

### Basic Server Connection

```powershell
# Get credentials and test connection
$cred = Get-PlexCredential
Test-PlexConnection -Credential $cred
```

### Get Server Information

```powershell
# Get credentials and server information
$cred = Get-PlexCredential
$serverInfo = Get-PlexServerInfo -Credential $cred
Write-Host "Server: $($serverInfo.FriendlyName) (v$($serverInfo.Version))"
```

### Work with Libraries

```powershell
# Get credentials and libraries
$cred = Get-PlexCredential

# Get all libraries
$libraries = Get-PlexLibraries -Credential $cred

# Get only movie libraries
$movieLibraries = Get-PlexLibraries -Credential $cred -LibraryType Movie

# Get items from a specific library
$items = Get-PlexLibraryItems -Credential $cred -LibraryId 1

# Get items with pagination and sorting
$items = Get-PlexLibraryItems -Credential $cred -LibraryId 1 -Limit 50 -Sort "titleSort"
```

### Get Media Information

```powershell
# Get detailed information about a specific media item
$cred = Get-PlexCredential
$mediaInfo = Get-PlexMediaInfo -Credential $cred -MediaId 12345
Write-Host "Title: $($mediaInfo.title)"
Write-Host "Year: $($mediaInfo.year)"
Write-Host "Rating: $($mediaInfo.rating)"
```

### Trigger Library Scans

```powershell
# Scan a specific library for new content
$cred = Get-PlexCredential
$success = Invoke-PlexLibraryScan -Credential $cred -LibraryId 1
if ($success) {
    Write-Host "Library scan initiated successfully"
}
```

## Authentication

The Plex module provides multiple ways to handle authentication:

### Get-PlexCredential Function

The `Get-PlexCredential` function provides a simple way to handle authentication:

- **Interactive Prompts**: Uses Windows credential dialog for secure input
- **Default Values**: Automatic localhost server detection
- **Token Generation**: Automatically generates authentication token from credentials
- **Credential Object**: Returns a PlexCredential object for use with other functions

### Manual Token Usage

Most functions also accept direct token parameters. You can obtain your token by:

1. Logging into your Plex account at https://app.plex.tv
2. Going to Settings > Account
3. Finding your token in the "Plex Token" section

### Environment Variables

For advanced usage, you can set environment variables for the default server:

```powershell
$env:PLEX_SERVER_URL = "http://your-server:32400"  # Optional, defaults to localhost
```

## Error Handling

The module provides comprehensive error handling with:

- Detailed error messages for common issues
- HTTP status code handling
- Validation of input parameters
- Consistent logging using the `Write-Message` function

## Dependencies

- **ScratchCore**: Required for `Write-Message` and other utility functions
- **PowerShell 5.1+**: Required for module functionality

## Constants

The module defines several constants for common Plex operations:

- **Default Port**: 32400
- **Default Protocol**: HTTP
- **Default Timeout**: 30 seconds
- **Library Types**: Movie, Show, Music, Photo, etc.
- **Media Types**: Movie, Episode, Season, Show, etc.

## Contributing

When contributing to this module:

1. Follow PowerShell best practices
2. Use the existing validation patterns
3. Include comprehensive help documentation
4. Use the `Write-Message` function for output
5. Add appropriate error handling
6. Update this README with new functionality

## License

© 2025 Dadstart. All rights reserved. 