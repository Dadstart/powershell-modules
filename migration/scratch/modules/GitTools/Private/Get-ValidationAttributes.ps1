function Get-ValidationAttributes {
    <#
    .SYNOPSIS
        Provides GitTools module-specific validation attributes for parameter validation patterns.
    
    .DESCRIPTION
        This function returns validation attributes specific to Git operations
        including branch names, commit messages, and Git-specific patterns.
    
    .EXAMPLE
        # Get all validation attributes
        $validators = Get-ValidationAttributes
        
    .EXAMPLE
        # Use in parameter validation
        [ValidateGitBranchAttribute()]
        [string]$BranchName
        
    .OUTPUTS
        [PSCustomObject] Object containing validation patterns and custom validation functions.
    
    .NOTES
        These validation patterns are specific to Git operations
        and should only be used within the GitTools module.
    #>
    
    return @{
        # Git branch name validation - letters, numbers, hyphens, underscores, forward slashes
        GitBranchPattern = '^[a-zA-Z0-9\-_/]+$'
        
        # Commit message validation - no empty or whitespace-only messages
        CommitMessagePattern = '^.+$'
        
        # Git-specific validation functions
        ValidateGitBranch = {
            param([string]$Branch)
            if (-not ($Branch -match '^[a-zA-Z0-9\-_/]+$')) {
                throw "Git branch name can only contain letters, numbers, hyphens, underscores, and forward slashes: $Branch"
            }
        }
        
        ValidateCommitMessage = {
            param([string]$Message)
            if ([string]::IsNullOrWhiteSpace($Message)) {
                throw "Commit message cannot be empty or whitespace-only"
            }
        }
        
        ValidateGitRepository = {
            param([string]$Path)
            if (-not (Test-Path (Join-Path $Path '.git'))) {
                throw "Directory is not a Git repository: $Path"
            }
        }
    }
}

# GitTools module-specific validation script blocks
$Script:ValidateGitBranchScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ([string]::IsNullOrWhiteSpace($Value))
    {
        return $true
    }
    
    if ($Value -match '^[a-zA-Z0-9\-_/]+$')
    {
        return $true
    }
    
    throw "Git branch name can only contain letters, numbers, hyphens, underscores, and forward slashes: '$Value'"
}

$Script:ValidateCommitMessageScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    
    if ([string]::IsNullOrWhiteSpace($Value))
    {
        return $true
    }
    
    if ($Value -match '^.+$')
    {
        return $true
    }
    
    throw "Commit message cannot be empty or whitespace-only: '$Value'"
}

$Script:ValidateGitRepositoryScript = {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        return $true
    }
    
    if (Test-Path -Path (Join-Path -Path $Path -ChildPath '.git'))
    {
        return $true
    }
    
    throw "Directory is not a Git repository: '$Path'"
} 