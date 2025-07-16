# Plex Module

A PowerShell module for Plex Media Server integration and management.

## Overview

The Plex module provides tools for:
- **Plex server connection** - Connect to and authenticate with Plex servers
- **Library management** - Browse and manage Plex libraries
- **Media information** - Retrieve detailed media metadata
- **Credential management** - Secure storage and retrieval of Plex credentials

## Requirements

- PowerShell 7.4 or higher
- **Plex Media Server** - Must be running and accessible
- **Plex account** - For authentication (optional, depending on server configuration)

## Installation

### Prerequisites

1. **Plex Media Server**:
   - Install Plex Media Server on your system
   - Ensure it's running and accessible
   - Note your server URL and port (default: <http://localhost:32400>)

2. **Network Access**:
   - Ensure PowerShell can access your Plex server
   - Configure firewall rules if necessary

### Module Installation

```powershell
# Clone the repository
git clone https://github.com/Dadstart/powershell-modules.git

# Import the Plex module
Import-Module .\Modules\Plex\PlexTools.psm1
```

## Functions

### Connection Management

#### `Test-PlexConnection`
Test connectivity to a Plex Media Server.

```powershell
# Test connection to local Plex server
Test-PlexConnection -ServerUrl "http://localhost:32400"

# Test connection with credentials
Test-PlexConnection -ServerUrl "http://plex.example.com:32400" -Token "your-token"
```

#### `Get-PlexCredential`
Retrieve stored Plex credentials or prompt for new ones.

```powershell
# Get stored credentials
$credential = Get-PlexCredential -ServerUrl "http://localhost:32400"

# Get credentials with prompt for new ones if not found
$credential = Get-PlexCredential -ServerUrl "http://localhost:32400" -PromptIfMissing
```

### Library Operations

#### `Get-PlexLibraries`
Retrieve a list of all libraries on the Plex server.

```powershell
# Get all libraries
$libraries = Get-PlexLibraries -ServerUrl "http://localhost:32400"

# Get libraries with details
$libraries = Get-PlexLibraries -ServerUrl "http://localhost:32400" -IncludeDetails
$libraries | ForEach-Object { "$($_.Name) - $($_.Type)" }
```

#### `Get-PlexLibraryItems`
Retrieve items from a specific Plex library.

```powershell
# Get all movies from Movies library
$movies = Get-PlexLibraryItems -ServerUrl "http://localhost:32400" -LibraryName "Movies"

# Get TV shows with filtering
$shows = Get-PlexLibraryItems -ServerUrl "http://localhost:32400" -LibraryName "TV Shows" -Filter "year=2023"

# Get items with pagination
$items = Get-PlexLibraryItems -ServerUrl "http://localhost:32400" -LibraryName "Music" -Limit 50 -Offset 100
```

### Media Information

#### `Get-PlexMediaInfo`
Get detailed information about a specific media item.

```powershell
# Get movie information
$movieInfo = Get-PlexMediaInfo -ServerUrl "http://localhost:32400" -ItemId "12345"

# Get TV episode information
$episodeInfo = Get-PlexMediaInfo -ServerUrl "http://localhost:32400" -ItemId "67890" -IncludeMetadata
```

### Credential Management

#### `PlexCredential`
A class for managing Plex authentication credentials.

```powershell
# Create a new credential object
$credential = [PlexCredential]::new("http://localhost:32400", "your-token")

# Store credentials securely
$credential.Save()

# Load stored credentials
$loadedCredential = [PlexCredential]::Load("http://localhost:32400")
```

## Examples

### Basic Plex Server Connection

```powershell
# Import the module
Import-Module .\Modules\Plex\PlexTools.psm1

# Test connection to Plex server
$serverUrl = "http://localhost:32400"
if (Test-PlexConnection -ServerUrl $serverUrl) {
    Write-Message "Successfully connected to Plex server" -Type Success
    
    # Get available libraries
    $libraries = Get-PlexLibraries -ServerUrl $serverUrl
    Write-Message "Found $($libraries.Count) libraries" -Type Info
} else {
    Write-Message "Failed to connect to Plex server" -Type Error
}
```

### Library Management

```powershell
# Get all libraries and their types
$libraries = Get-PlexLibraries -ServerUrl "http://localhost:32400" -IncludeDetails

foreach ($library in $libraries) {
    Write-Message "Library: $($library.Name) ($($library.Type))" -Type Info
    
    # Get some items from each library
    $items = Get-PlexLibraryItems -ServerUrl "http://localhost:32400" -LibraryName $library.Name -Limit 5
    
    foreach ($item in $items) {
        Write-Message "  - $($item.Title)" -Type Info
    }
}
```

### Media Analysis

```powershell
# Analyze movies in the Movies library
$movies = Get-PlexLibraryItems -ServerUrl "http://localhost:32400" -LibraryName "Movies"

$movieStats = @{
    TotalMovies = $movies.Count
    AverageRating = ($movies | Measure-Object -Property Rating -Average).Average
    Genres = $movies | ForEach-Object { $_.Genre } | Sort-Object | Get-Unique
}

Write-Message "Total Movies: $($movieStats.TotalMovies)" -Type Info
Write-Message "Average Rating: $([math]::Round($movieStats.AverageRating, 2))" -Type Info
Write-Message "Genres: $($movieStats.Genres -join ', ')" -Type Info
```

### Credential Management

```powershell
# Function to get or create Plex credentials
function Get-PlexCredentials {
    param(
        [string]$ServerUrl
    )
    
    try {
        # Try to load existing credentials
        $credential = Get-PlexCredential -ServerUrl $ServerUrl
        
        if (-not $credential) {
            Write-Message "No stored credentials found. Please enter your Plex token:" -Type Warning
            $token = Read-Host -Prompt "Plex Token" -AsSecureString
            
            # Convert secure string to plain text
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
            $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
            # Create and save new credential
            $credential = [PlexCredential]::new($ServerUrl, $plainToken)
            $credential.Save()
            
            Write-Message "Credentials saved successfully" -Type Success
        }
        
        return $credential
    }
    catch {
        Write-Message "Error managing credentials: $($_.Exception.Message)" -Type Error
        return $null
    }
}

# Use the function
$credential = Get-PlexCredentials -ServerUrl "http://localhost:32400"
```

### Automated Library Monitoring

```powershell
# Function to monitor library changes
function Monitor-PlexLibrary {
    param(
        [string]$ServerUrl,
        [string]$LibraryName,
        [int]$CheckInterval = 300  # 5 minutes
    )
    
    $lastCount = 0
    
    while ($true) {
        try {
            $items = Get-PlexLibraryItems -ServerUrl $ServerUrl -LibraryName $LibraryName
            $currentCount = $items.Count
            
            if ($currentCount -ne $lastCount) {
                $difference = $currentCount - $lastCount
                $changeType = if ($difference -gt 0) { "added" } else { "removed" }
                
                Write-Message "Library '$LibraryName' has $([math]::Abs($difference)) items $changeType" -Type Info
                Write-Message "Total items: $currentCount" -Type Info
                
                $lastCount = $currentCount
            }
            
            Start-Sleep -Seconds $CheckInterval
        }
        catch {
            Write-Message "Error monitoring library: $($_.Exception.Message)" -Type Error
            Start-Sleep -Seconds 60  # Wait 1 minute before retrying
        }
    }
}

# Start monitoring
Monitor-PlexLibrary -ServerUrl "http://localhost:32400" -LibraryName "Movies"
```

## Configuration

### Plex Server Settings

Configure your Plex server settings:

```powershell
# Common Plex server URLs
$localPlex = "http://localhost:32400"
$remotePlex = "http://your-plex-server:32400"

# Test both connections
Test-PlexConnection -ServerUrl $localPlex
Test-PlexConnection -ServerUrl $remotePlex
```

### Authentication

The module supports multiple authentication methods:

1. **Token-based authentication** (recommended)
2. **Username/password authentication** (if enabled on server)
3. **No authentication** (for local servers with no authentication required)

## Error Handling

All functions include comprehensive error handling and will provide detailed error messages when operations fail.

## Security

- Credentials are stored securely using Windows Credential Manager
- Tokens are encrypted when stored
- No credentials are logged or displayed in plain text

## Performance

- **Connection pooling** for efficient server communication
- **Caching** of library information where appropriate
- **Pagination** support for large libraries

## Integration

The Plex module integrates with:
- **Media module** - For file operations and media processing
- **Shared module** - For consistent logging and error handling
- **Other modules** - For comprehensive media management workflows

## Contributing

When adding new functions to the Plex module:

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
