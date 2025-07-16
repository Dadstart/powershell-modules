# Contributing to PowerShell Modules by Dadstart

Thank you for your interest in contributing to this PowerShell modules project! This document provides guidelines for contributing to ensure consistency and quality.

## Prerequisites

- **PowerShell 7.4 or higher** (LTS version)
- **Git** for version control
- **Pester** for testing (will be installed automatically by build script)

## Development Setup

1. **Fork and clone the repository**
   ```powershell
   git clone https://github.com/your-username/powershell-modules.git
   cd powershell-modules
   ```

2. **Verify PowerShell version**
   ```powershell
   $PSVersionTable.PSVersion
   # Should be 7.4.0 or higher
   ```

3. **Run the build script to set up the environment**
   ```powershell
   .\build.ps1 -Task Build
   ```

## Module Structure

Each PowerShell module should follow this structure:

```
ModuleName/
├── ModuleName.psd1          # Module manifest
├── ModuleName.psm1          # Module script (optional)
├── Public/                  # Exported functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/                 # Internal functions
│   ├── Internal-Function.ps1
│   └── Helper-Function.ps1
├── Tests/                   # Pester tests
│   ├── ModuleName.Tests.ps1
│   └── Get-Something.Tests.ps1
└── README.md               # Module documentation
```

## Module Manifest Requirements

Each module manifest (`.psd1`) must include:

```powershell
@{
    ModuleVersion = '0.0.1'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    # ... other manifest properties
}
```

## Coding Standards

### PowerShell 7.4+ Features

You can use PowerShell 7.4+ features including:

- **Ternary operators**: `$result = $condition ? 'true' : 'false'`
- **Null coalescing**: `$value = $null ?? 'default'`
- **Pipeline chain operators**: `&&` and `||`
- **ForEach-Object -Parallel** (for performance-critical operations)
- **Simplified error handling**: `try { ... } catch { ... }`

### Formatting

See [FORMATTING.md](FORMATTING.md).

## Testing

** UNDER REVIEW ** 

### Writing Tests

1. **Use Pester 5.x syntax**
   ```powershell
   Describe 'Get-Something' {
       BeforeAll {
           # Setup code
       }
       
       It 'Should return expected result' {
           $result = Get-Something -Parameter 'value'
           $result | Should -Not -BeNullOrEmpty
       }
       
       It 'Should throw error for invalid input' {
           { Get-Something -Parameter $null } | Should -Throw
       }
   }
   ```

2. **Test both positive and negative scenarios**
3. **Mock external dependencies**
4. **Use descriptive test names**

### Running Tests

```powershell
# Run all tests
.\build.ps1 -Task Test

# Run specific test file
Invoke-Pester -Path "Tests/ModuleName.Tests.ps1"
```

## Pull Request Process

1. **Create a feature branch**
   ```powershell
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the coding standards
   - Add tests for new functionality
   - Update documentation

3. **Test your changes**
   ```powershell
   .\build.ps1 -Task All
   ```

4. **Commit your changes**
   ```powershell
   git add .
   git commit -m "Add feature: brief description"
   ```

5. **Push and create a pull request**
   ```powershell
   git push origin feature/your-feature-name
   ```

## Commit Message Guidelines

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `bug`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Test changes

Examples:
```
feat(module): add Get-UserData cmdlet
fix(build): resolve PowerShell 7.4 compatibility issue
docs(readme): update installation instructions
```

## Version Management

- Follow [Semantic Versioning](https://semver.org/)
- Update module version in manifest when making changes
- Document breaking changes in release notes

## Questions or Issues?

- Create an issue for bugs or feature requests
- Use discussions for questions and general help
- Join our community channels (if available)

Thank you for contributing to PowerShell Modules by Dadstart! 