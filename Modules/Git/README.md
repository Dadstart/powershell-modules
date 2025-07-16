# Git Module

A PowerShell module for enhanced Git operations and workflow management.

## Overview

The Git module provides tools for:
- **Enhanced Git operations** - Streamlined Git workflows
- **Directory management** - Move and organize Git repositories
- **Commit management** - Create standardized commits
- **Pull request automation** - Generate and manage pull requests

## Requirements

- PowerShell 7.4 or higher
- **Git** - Must be installed and available in PATH

## Installation

### Prerequisites

1. **Install Git**:
   ```powershell
   # Using Winget
   winget install Git.Git
   
   # Using Chocolatey (alternative)
   choco install git
   ```

2. **Verify Git installation**:
   ```powershell
   git --version
   ```

### Module Installation

```powershell
# Clone the repository
git clone https://github.com/Dadstart/powershell-modules.git

# Import the Git module
Import-Module .\Modules\Git\GitTools.psm1
```

## Functions

### Repository Management

#### `Move-GitDirectory`
Move a Git repository to a new location while preserving Git history and configuration.

```powershell
# Move repository to new location
Move-GitDirectory -SourcePath "C:\OldRepo" -DestinationPath "C:\NewRepo"

# Move with backup
Move-GitDirectory -SourcePath "C:\OldRepo" -DestinationPath "C:\NewRepo" -CreateBackup
```

### Commit Operations

#### `New-GitCommit`
Create standardized Git commits with consistent formatting and validation.

```powershell
# Basic commit
New-GitCommit -Message "Add new feature" -Type "feat"

# Commit with scope
New-GitCommit -Message "Fix login bug" -Type "fix" -Scope "auth"

# Commit with breaking change
New-GitCommit -Message "Update API endpoints" -Type "feat" -BreakingChange
```

**Commit Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes
- `refactor` - Code refactoring
- `test` - Test changes
- `chore` - Maintenance tasks

### Pull Request Management

#### `New-GitPullRequest`
Create and manage pull requests with automated workflows.

```powershell
# Create pull request
New-GitPullRequest -Title "Add new feature" -Body "This PR adds..." -SourceBranch "feature/new-feature"

# Create with labels
New-GitPullRequest -Title "Fix bug" -Body "Fixes issue #123" -Labels @("bug", "high-priority")

# Create with reviewers
New-GitPullRequest -Title "Update docs" -Body "Updates documentation" -Reviewers @("user1", "user2")
```

## Examples

### Basic Git Workflow

```powershell
# Import the module
Import-Module .\Modules\Git\GitTools.psm1

# Create a new feature branch
git checkout -b feature/new-feature

# Make changes to files
# ...

# Stage changes
git add .

# Create a standardized commit
New-GitCommit -Message "Add user authentication feature" -Type "feat" -Scope "auth"

# Push changes
git push origin feature/new-feature

# Create pull request
New-GitPullRequest -Title "Add user authentication" -Body "Implements user login/logout functionality" -SourceBranch "feature/new-feature"
```

### Repository Organization

```powershell
# Move a repository to a new location
Move-GitDirectory -SourcePath "C:\Projects\OldProject" -DestinationPath "C:\GitRepos\NewProject"

# Verify the move was successful
git status
git log --oneline -5
```

### Automated Commit Workflow

```powershell
# Function to create commits based on file changes
function New-StandardizedCommit {
    param(
        [string]$Type = "feat",
        [string]$Scope,
        [string]$Message
    )
    
    # Stage all changes
    git add .
    
    # Create commit
    New-GitCommit -Message $Message -Type $Type -Scope $Scope
    
    Write-Message "Created $Type commit: $Message" -Type Success
}

# Use the function
New-StandardizedCommit -Type "fix" -Scope "ui" -Message "Fix button alignment issue"
```

### Pull Request Automation

```powershell
# Function to create PRs for feature branches
function New-FeaturePullRequest {
    param(
        [string]$FeatureName,
        [string]$Description
    )
    
    $branchName = "feature/$FeatureName"
    $title = "Add $FeatureName"
    
    # Ensure we're on the feature branch
    git checkout $branchName
    
    # Create pull request
    New-GitPullRequest -Title $title -Body $Description -SourceBranch $branchName -Labels @("enhancement")
    
    Write-Message "Created pull request for $FeatureName" -Type Success
}

# Use the function
New-FeaturePullRequest -FeatureName "dark-mode" -Description "Implements dark mode theme for the application"
```

## Configuration

The Git module integrates with the Shared module's `Write-Message` system for consistent logging and output formatting.

### Git Configuration

Ensure your Git configuration is set up properly:

```powershell
# Set up user information
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set up default branch
git config --global init.defaultBranch main
```

## Best Practices

### Commit Messages

- Use conventional commit format
- Keep messages concise but descriptive
- Use appropriate commit types
- Include scope when relevant

### Branch Management

- Use feature branches for new development
- Keep branches focused on single features
- Delete branches after merging
- Use descriptive branch names

### Pull Requests

- Write clear, descriptive titles
- Include detailed descriptions
- Add appropriate labels
- Request reviews from relevant team members

## Error Handling

All functions include comprehensive error handling and will provide detailed error messages when operations fail.

## Integration

The Git module works seamlessly with:
- **GitHub** - Pull request creation and management
- **GitLab** - Repository operations
- **Azure DevOps** - Git operations
- **Other Git hosting services** - Standard Git operations

## Contributing

When adding new functions to the Git module:

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
