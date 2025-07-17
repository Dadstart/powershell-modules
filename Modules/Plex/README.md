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

#### `New-PlexConnection`
Create a new Plex connection by prompting for authentication credentials.

```powershell
# Create connection with default localhost server
$connection = New-PlexConnection

# Create connection with specific server URL
$connection = New-PlexConnection -ServerUrl "http://192.168.1.100:32400"

# Create connection with pre-filled username
$connection = New-PlexConnection -ServerUrl "http://plex.example.com:32400" -UserName "admin"
```

### Library Operations

#### `Get-PlexLibraries`
Retrieve a list of all libraries on the Plex server.

```powershell
# Get all libraries
$connection = New-PlexConnection
$libraries = Get-PlexLibraries $connection

# Get libraries with details
$libraries = Get-PlexLibraries $connection -IncludeDetails
$libraries | ForEach-Object { "$($_.Name) - $($_.Type)" }
```

#### `Get-PlexLibraryItems`
Retrieve items from a specific Plex library.

```powershell
# Get all movies from Movies library
$connection = New-PlexConnection
$movies = Get-PlexLibraryItems $connection -LibraryId 1

# Get TV shows with filtering
$shows = Get-PlexLibraryItems $connection -LibraryId 2 -Limit 50

# Get items with pagination
$items = Get-PlexLibraryItems $connection -LibraryId 3 -Limit 50 -Offset 100
```

### Media Information

#### `Get-PlexMediaInfo`
Get detailed information about a specific media item.

```powershell
# Get movie information
$connection = New-PlexConnection
$movieInfo = Get-PlexMediaInfo $connection -MediaId 12345

# Get TV episode information
$episodeInfo = Get-PlexMediaInfo $connection -MediaId 67890
```

#### `Get-PlexServerInfo`
Get information about the Plex Media Server.

```powershell
# Get server information
$connection = New-PlexConnection
$serverInfo = Get-PlexServerInfo $connection

# Display server details
$serverInfo | Format-List
```

#### `Invoke-PlexLibraryScan`
Trigger a library scan on the Plex Media Server.

```powershell
# Scan all libraries
$connection = New-PlexConnection
Invoke-PlexLibraryScan $connection

# Scan specific library
Invoke-PlexLibraryScan $connection -LibraryId 1
```

#### `Invoke-PlexApiRequest`
Make direct API requests to the Plex Media Server.

```powershell
# Get server capabilities
$connection = New-PlexConnection
$capabilities = Invoke-PlexApiRequest -Uri "/" $connection

# Get specific library items
$items = Invoke-PlexApiRequest -Uri "/library/sections/1/all" $connection
```

### Connection Management

#### `PlexToolsConnection`
A class for managing Plex server connections and authentication.

```powershell
# Create a new connection object
$connection = [PlexToolsConnection]::new($credential, "http://localhost:32400", "your-token")

# Get connection headers for API requests
$headers = $connection.GetHeaders()

# Access connection properties
$connection.ServerUrl
$connection.TimeoutSeconds
```

## Examples

### Basic Plex Server Connection

```powershell
# Import the module
Import-Module .\Modules\Plex\PlexTools.psm1

# Test connection to Plex server
$connection = New-PlexConnection
if (Test-PlexConnection $connection) {
    Write-Message "Successfully connected to Plex server" -Type Success
    
    # Get available libraries
    $libraries = Get-PlexLibraries $connection
    Write-Message "Found $($libraries.Count) libraries" -Type Info
} else {
    Write-Message "Failed to connect to Plex server" -Type Error
}
```

### Library Management

```powershell
# Get all libraries and their types
$connection = New-PlexConnection
$libraries = Get-PlexLibraries $connection -IncludeDetails

foreach ($library in $libraries) {
    Write-Message "Library: $($library.Name) ($($library.Type))" -Type Info
    
    # Get some items from each library
    $items = Get-PlexLibraryItems $connection -LibraryId $library.Id -Limit 5
    
    foreach ($item in $items) {
        Write-Message "  - $($item.Title)" -Type Info
    }
}
```

### Media Analysis

```powershell
# Analyze movies in the Movies library
$connection = New-PlexConnection
$movies = Get-PlexLibraryItems $connection -LibraryId 1

$movieStats = @{
    TotalMovies = $movies.Count
    AverageRating = ($movies | Measure-Object -Property Rating -Average).Average
    Genres = $movies | ForEach-Object { $_.Genre } | Sort-Object | Get-Unique
}

Write-Message "Total Movies: $($movieStats.TotalMovies)" -Type Info
Write-Message "Average Rating: $([math]::Round($movieStats.AverageRating, 2))" -Type Info
Write-Message "Genres: $($movieStats.Genres -join ', ')" -Type Info
```

### Connection Management

```powershell
# Function to create Plex connection with defaults
function New-PlexConnectionWithDefaults {
    param(
        [string]$ServerUrl = "http://localhost:32400",
        [string]$UserName
    )
    
    try {
        # Create new connection with credential prompt
        $connection = New-PlexConnection -ServerUrl $ServerUrl -UserName $UserName
        
        Write-Message "Connection created successfully" -Type Success
        return $connection
    }
    catch {
        Write-Message "Error creating connection: $($_.Exception.Message)" -Type Error
        return $null
    }
}

# Use the function
$connection = New-PlexConnectionWithDefaults -ServerUrl "http://localhost:32400"
```

### Automated Library Monitoring

```powershell
# Function to monitor library changes
function Monitor-PlexLibrary {
    param(
        [string]$LibraryName,
        [int]$CheckInterval = 300  # 5 minutes
    )
    
    $lastCount = 0
    
    while ($true) {
        try {
            $connection = New-PlexConnection
            $items = Get-PlexLibraryItems $connection -LibraryId 1
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
Monitor-PlexLibrary -LibraryName "Movies"
```

## Configuration

### Message Configuration

You can configure the message formatting behavior globally:

```powershell
# Enable timestamps and file logging
Set-WriteMessageConfig -TimeStamp -LogFile "C:\logs\plex-operations.log"

# Enable JSON output
Set-WriteMessageConfig -AsJson

# Enable call-site context
Set-WriteMessageConfig -IncludeContext

# Customize colors
Set-WriteMessageConfig -LevelColors @{
    'Info' = 'Blue'
    'Success' = 'Green'
    'Warning' = 'Yellow'
    'Error' = 'Red'
}

# Reset to defaults
Set-WriteMessageConfig -Reset
```

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
