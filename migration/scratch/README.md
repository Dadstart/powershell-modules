# Scratch Repository

A comprehensive development workspace containing PowerShell modules, tools, and projects for various automation and development tasks.

## 📁 Repository Structure

```
scratch/
├── modules/                          # PowerShell modules
│   ├── Video/                        # Video processing and conversion
│   ├── GitTools/                     # Git automation and workflow
│   └── Scratch/                  # Core utilities and helpers
├── tools/                            # External tool configurations
│   ├── handbrake/                    # HandBrake CLI settings
│   ├── ffmpeg/                       # FFmpeg configurations
│   └── other-tools/                  # Other external tools
├── projects/                         # Non-PowerShell projects
│   ├── nodejs/                       # Node.js projects
│   ├── python/                       # Python projects
│   ├── dotnet/                       # .NET projects
│   └── other/                        # Other language projects
├── scripts/                          # Standalone scripts
│   ├── powershell/                   # PowerShell scripts
│   ├── nodejs/                       # Node.js scripts
│   ├── python/                       # Python scripts
│   └── other/                        # Other script types
├── utilities/                        # Development utilities
│   ├── install-modules.ps1           # Install all modules
│   ├── update-modules.ps1            # Update all modules
│   └── test-all.ps1                  # Run all tests
├── docs/                             # Documentation
│   ├── PowerShell_Best_Practices.md
│   ├── module-guides/                # Module documentation
│   └── project-setup/                # Setup guides
├── config/                           # Configuration files
│   ├── PSScriptAnalyzerSettings.psd1
│   └── other-configs/                # Other configs
└── temp/                             # Temporary files
```

## 🚀 Quick Start

### Install All PowerShell Modules

```powershell
# From the repository root
.\utilities\install-modules.ps1

# Or with function listing
.\utilities\install-modules.ps1 -ShowFunctions

# Install specific modules only
.\utilities\install-modules.ps1 -Modules Video,GitTools
```

### Update Modules

```powershell
.\utilities\update-modules.ps1
```

### Run Tests

```powershell
.\utilities\test-all.ps1
```

## 📦 PowerShell Modules

### Video Module
Video processing, conversion, and management including HandBrake integration, chapter extraction, and TVDb episode information retrieval.

**Key Functions:**
- `Convert-VideoFiles` - Convert video files using HandBrake
- `Get-ChapterInfo` - Extract chapter information
- `Get-TvDbEpisodeInfo` - Retrieve TVDb episode data
- `Invoke-SafeFileRename` - Safe file renaming with conflict resolution

### GitTools Module
Git automation and workflow management for streamlined version control operations.

**Key Functions:**
- `New-GitCommit` - Create commits with branch management
- `New-GitPullRequest` - Create pull requests
- `Move-GitDirectory` - Move directories with Git tracking

### Scratch Module
Core utilities and helper functions for common development tasks.

**Key Functions:**
- (To be added as needed)

## 🛠️ External Tools

### HandBrake Configurations
Located in `tools/handbrake/`, these JSON files contain custom settings for HandBrakeCLI.exe:

- 4K UHD conversion settings
- Blu-ray recommended settings
- DVD conversion profiles
- Web-optimized settings

## 📚 Documentation

- [PowerShell Best Practices](docs/PowerShell_Best_Practices.md) - Implementation status of PowerShell best practices
- Module-specific documentation in `docs/module-guides/`
- Project setup guides in `docs/project-setup/`

## 🔧 Configuration

- PSScriptAnalyzer settings in `config/PSScriptAnalyzerSettings.psd1`
- Additional configurations in `config/other-configs/`

## 🧪 Testing

Each module includes a `test/` directory for module-specific tests. Run all tests with:

```powershell
.\utilities\test-all.ps1
```

## 📝 Development

### Adding New Modules

1. Create a new directory in `modules/`
2. Follow the standard structure: `Public/`, `Private/`, `test/`
3. Create module manifest (`.psd1`) and loader (`.psm1`)
4. Update utility scripts to include the new module

### Adding New Projects

1. Create a new directory in `projects/` under the appropriate language folder
2. Follow language-specific conventions
3. Add documentation in `docs/project-setup/`

## 🤝 Contributing

1. Use the GitTools module for streamlined Git operations
2. Follow PowerShell best practices as documented
3. Add tests for new functionality
4. Update documentation as needed

## 📄 License

This repository contains various tools and modules for personal and professional development use. 