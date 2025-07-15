# PowerShell Modules

A collection of PowerShell modules designed for modern PowerShell environments, targeting PowerShell 7.4 LTS.

## Overview

This repository contains multiple PowerShell modules that follow best practices and community standards:

- **Media**: Media file management, conversion, and optimization
- **Plex**: Plex Media Server integration and management
- **Rip**: Media ripping and extraction tools
- **Git**: Enhanced Git operations and workflow management

## Requirements

- **PowerShell**: 7.4 or higher (LTS version)
- **Operating System**: Windows, macOS, or Linux
- **Platform**: .NET 6.0 or higher

## Project Structure

```
powershell-modules/
├── Modules/
│   ├── Shared/
│   │   └── Public/
│   │       ├── Get-Path.ps1          # Shared path validation function
│   │       ├── Write-Message.ps1     # Shared logging function
│   │       └── Shared.ps1            # Shared module loader
│   ├── Media/
│   │   ├── Classes/
│   │   │   └── MediaFile.ps1         # MediaFile class
│   │   ├── Private/
│   │   │   ├── Convert-VideoFile.ps1 # Private conversion functions
│   │   │   ├── Convert-AudioFile.ps1
│   │   │   ├── Convert-ImageFile.ps1
│   │   │   ├── Optimize-VideoFile.ps1
│   │   │   ├── Optimize-AudioFile.ps1
│   │   │   ├── Optimize-ImageFile.ps1
│   │   │   ├── Get-AllMetadata.ps1
│   │   │   ├── Get-BasicMetadata.ps1
│   │   │   ├── Get-TechnicalMetadata.ps1
│   │   │   └── Get-TagMetadata.ps1
│   │   ├── Public/
│   │   │   ├── Get-MediaInfo.ps1     # Public exported functions
│   │   │   ├── Convert-Media.ps1
│   │   │   ├── Optimize-Media.ps1
│   │   │   └── Get-MediaMetadata.ps1
│   │   ├── Media.psd1                # Module manifest
│   │   └── Media.psm1                # Module root script
│   ├── Plex/                         # Plex module (to be implemented)
│   ├── Rip/                          # Rip module (to be implemented)
│   └── Git/                          # Git module (to be implemented)
├── Tests/
│   ├── Unit/
│   │   └── Media/
│   │       └── Get-MediaInfo.Tests.ps1
│   ├── Integration/
│   └── Performance/
├── .vscode/
│   └── settings.json                 # VS Code configuration
├── PowerShellProfile.ps1             # Development profile
├── build.ps1                         # Build script
└── README.md
```

## Installation

### Development Installation

1. Clone this repository:
   ```powershell
   git clone https://github.com/Dadstart/powershell-modules.git
   cd powershell-modules
   ```

2. Load the development profile for IntelliSense support:
   ```powershell
   . .\PowerShellProfile.ps1
   ```

3. Import individual modules:
   ```powershell
   Import-Module .\Modules\Media\Media.psd1
   ```

### Production Installation

```powershell
# Install from PowerShell Gallery (when published)
Install-Module -Name Media -Force
Install-Module -Name Plex -Force
Install-Module -Name Rip -Force
Install-Module -Name Git -Force
```

## Usage Examples

### Media Module

```powershell
# Get information about media files
Get-MediaInfo -Path "C:\Videos" -Recurse

# Convert media files
Convert-Media -InputPath "video.avi" -Format "mp4" -Quality High

# Optimize media files
Optimize-Media -Path "C:\Images" -Strategy Size -Backup

# Extract metadata
Get-MediaMetadata -Path "C:\Music" -Recurse -MetadataType Technical
```

### Shared Functions

```powershell
# Validate and normalize paths
$ValidPath = Get-Path -Path "C:\temp\file.txt" -PathType File -MustExist

# Write formatted messages
Write-Message -Message "Operation completed" -Level Success
Write-Message -Message "Warning message" -Level Warning -LogToFile
```

## Development

### Building

```powershell
# Build all modules
.\build.ps1 -Task Build

# Run tests
.\build.ps1 -Task Test

# Clean build output
.\build.ps1 -Task Clean

# Build and package
.\build.ps1 -Task All
```

### Testing

```powershell
# Run all tests
Invoke-Pester -Path Tests

# Run specific test file
Invoke-Pester -Path Tests\Unit\Media\Get-MediaInfo.Tests.ps1

# Run tests with coverage
Invoke-Pester -Path Tests -CodeCoverage Modules\Media\*.ps1
```

### Module Development

1. **Create a new module**:
   - Copy the Media module structure as a template
   - Update the module manifest (.psd1)
   - Implement public functions in the Public folder
   - Implement private functions in the Private folder
   - Add classes in the Classes folder

2. **Follow naming conventions**:
   - Public functions: Verb-Noun format
   - Private functions: Verb-Noun format (not exported)
   - Classes: PascalCase
   - Files: Verb-Noun.ps1 format

3. **Documentation**:
   - Use comment-based help for all functions
   - Include examples and parameter descriptions
   - Document return types and outputs

### VS Code Integration

The project includes VS Code configuration for:
- PowerShell 7.4 as the default version
- Code formatting rules
- IntelliSense support for modules
- File associations for PowerShell files

## Module Details

### Media Module

**Functions**:
- `Get-MediaInfo`: Retrieve detailed information about media files
- `Convert-Media`: Convert media files between formats
- `Optimize-Media`: Optimize media files for size/quality
- `Get-MediaMetadata`: Extract metadata from media files

**Classes**:
- `MediaFile`: Represents a media file with properties and methods

### Shared Functions

**Get-Path**: Validates and normalizes file paths with type checking
**Write-Message**: Provides consistent logging and message formatting

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the coding standards
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

### Coding Standards

- Use PowerShell 7.4+ features
- Follow PSScriptAnalyzer rules
- Use comment-based help for all functions
- Implement proper error handling
- Write unit tests for all public functions
- Use the shared functions for common operations

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Notice

For third-party component attributions, see the [NOTICE](NOTICE) file.

## Support

- **Issues**: [GitHub Issues](https://github.com/Dadstart/powershell-modules/issues)
- **Documentation**: [Wiki](https://github.com/Dadstart/powershell-modules/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/Dadstart/powershell-modules/discussions)
