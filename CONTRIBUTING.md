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

```text
ModuleName/
├── ModuleName.psd1          # Module manifest
├── ModuleName.psm1          # Module script (optional)
├── Public/                  # Exported functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/                 # Internal functions
│   ├── Internal-Function.ps1
│   └── Helper-Function.ps1
└── README.md               # Module documentation
```

Tests are organized in a separate `Tests/` directory at the project root:

```text
Tests/
├── Unit/                    # Unit tests
│   ├── ModuleName/          # Module-specific tests
│   │   ├── Get-Something.Tests.ps1
│   │   └── Set-Something.Tests.ps1
│   └── Shared/              # Shared module tests
│       └── Write-Message.Tests.ps1
├── Integration/             # Integration tests
└── Performance/             # Performance tests
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

### Code Style

1. **Use approved verbs** for cmdlet names
   ```powershell
   # Good
   Get-UserData
   Set-Configuration
   
   # Avoid
   Retrieve-UserData
   Update-Configuration
   ```

2. **Include comprehensive help**
   ```powershell
   <#
   .SYNOPSIS
       Brief description of what the cmdlet does.
   
   .DESCRIPTION
       Detailed description of the cmdlet functionality.
   
   .PARAMETER ParameterName
       Description of the parameter.
   
   .EXAMPLE
       Get-Something -ParameterName "Value"
       Description of what this example does.
   
   .OUTPUTS
       Type of object returned.
   
   .LINK
       Related cmdlets or documentation.
   #>
   ```

3. **Use parameter validation**
   ```powershell
   [Parameter(Mandatory = $true)]
   [ValidateNotNullOrEmpty()]
   [string]$ParameterName
   ```

4. **Handle errors gracefully**
   ```powershell
   try {
       # Your code here
   }
   catch {
       Write-Error "Failed to perform operation: $($_.Exception.Message)"
       return
   }
   ```

## Testing

### Writing Tests

1. **Use Pester 5.x syntax with proper structure**
   ```powershell
   BeforeAll {
       # Import the module to test
       $modulePath = Join-Path $PSScriptRoot '..\..\..\Modules\ModuleName\Public\Get-Something.ps1'
       . $modulePath
   }

   Describe 'Get-Something' {
       BeforeEach {
           # Setup for each test
       }

       Context 'Basic Functionality' {
           It 'Should return expected result' {
               $result = Get-Something -Parameter 'value'
               $result | Should -Not -BeNullOrEmpty
           }

           It 'Should throw error for invalid input' {
               { Get-Something -Parameter $null } | Should -Throw
           }
       }

       Context 'Edge Cases' {
           It 'Should handle empty input gracefully' {
               { Get-Something -Parameter '' } | Should -Not -Throw
           }
       }
   }
   ```

2. **Test organization guidelines:**
   - Use `BeforeAll` for module imports and one-time setup
   - Use `BeforeEach` for per-test setup and cleanup
   - Use `AfterAll` for cleanup
   - Group related tests in `Context` blocks
   - Test both positive and negative scenarios
   - Mock external dependencies when appropriate
   - Use descriptive test names that explain the expected behavior

3. **Test file naming:**
   - Unit tests: `FunctionName.Tests.ps1`
   - Place in appropriate module directory under `Tests/Unit/`
   - Shared module tests go in `Tests/Unit/Shared/`

### Running Tests

#### Using the Build Script (Recommended)
```powershell
# Run all tests with code coverage
.\build.ps1 -Task Test

# Run tests only (no build)
.\build.ps1 -Task TestOnly

# Run tests with specific configuration
.\build.ps1 -Task Test -Configuration Debug
```

#### Using Pester Directly
```powershell
# Run all tests
Invoke-Pester -Configuration PesterConfiguration.psd1

# Run specific test file
Invoke-Pester -Path 'Tests/Unit/ModuleName/Get-Something.Tests.ps1'

# Run tests for a specific module
Invoke-Pester -Path 'Tests/Unit/ModuleName/'

# Run with verbose output
Invoke-Pester -Configuration PesterConfiguration.psd1 -Output Detailed

# Run tests and generate coverage report
Invoke-Pester -Configuration PesterConfiguration.psd1 -CodeCoverageOutputFormat JaCoCo
```

#### Test Output
- Test results are saved to `BuildOutput/TestResults.xml`
- Code coverage reports are saved to `BuildOutput/CodeCoverage.xml`
- Console output shows detailed test progress and results

#### Test Categories
- **Unit Tests**: Test individual functions in isolation
- **Integration Tests**: Test interactions between modules
- **Performance Tests**: Test performance characteristics

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
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/tooling changes

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