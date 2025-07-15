# VideoUtility Module Version History

## Version 0.2.0 (2025-06-26)

### Module Rename

- Renamed module from Video to VideoUtility
- Updated all file references and documentation
- Maintained all existing functionality and structure

## Version 0.1.0 (2025-06-26)

### Initial Prerelease

- Created VideoUtility PowerShell module with proper structure
- Added sample `Get-VideoInfo` function
- Added private helper function `Test-VideoFile`
- Implemented installation and uninstallation scripts
- Added comprehensive documentation and README
- Configured for PowerShell 7.0+ compatibility
- Follows PowerShell best practices and module guidelines

### Features

- Module manifest with proper metadata
- Public/Private function organization
- Cross-platform support (Windows, macOS, Linux)
- Comprehensive error handling
- Verbose logging support
- Parameter validation
- Help documentation for all functions

### Structure

```PowerShell
VideoUtility/
├── VideoUtility.psd1        # Module manifest
├── VideoUtility.psm1        # Root module file
├── Install.ps1              # Installation script
├── QuickInstall.ps1         # Quick installation script
├── Uninstall.ps1            # Uninstallation script
├── README.md                # Module documentation
├── VERSION.md               # Version history
├── Public/                  # Public functions
│   └── Get-VideoInfo.ps1    # Sample public function
└── Private/                 # Private helper functions
    └── Test-VideoFile.ps1   # Sample private function
```
