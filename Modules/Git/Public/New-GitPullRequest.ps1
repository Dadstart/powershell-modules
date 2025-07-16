function New-GitPullRequest {
<#
.SYNOPSIS
    Create a new Git pull request for the current branch.
.DESCRIPTION
    This function creates a pull request for the current branch against the main branch and opens it in the browser.
.PARAMETER Title
    The title for the pull request. If not provided, uses the last commit message.
.EXAMPLE
    New-GitPullRequest
    Creates a PR with the last commit message as the title.
.EXAMPLE
    New-GitPullRequest -Title "Add new feature"
    Creates a PR with the specified title.
.NOTES
    This function should be run from within a git repository.
#>
    [CmdletBinding()]
    param(
        [string]$Title
    )
    Write-Message "Starting New-GitPullRequest function" -Type Debug
    Write-Message "Title parameter: '$Title'" -Type Debug
    # Get the current branch name
    Write-Message "Getting current branch name" -Type Debug
    $branch = git rev-parse --abbrev-ref HEAD
    Write-Message "Current branch: $branch" -Type Debug
    # Use the provided title, or fall back to the last commit message
    if ([string]::IsNullOrWhiteSpace($Title)) {
        Write-Message "No title provided, getting last commit message" -Type Debug
        $prTitle = git log -1 --pretty=%s
        Write-Message "Using last commit message as title: $prTitle" -Type Debug
    } else {
        Write-Message "Using provided title: $Title" -Type Debug
        $prTitle = $Title
    }
    Write-Message "Creating pull request for branch '$branch' with title '$prTitle'" -Type Verbose
    # Create the PR
    Write-Message "Executing gh pr create command" -Type Debug
    gh pr create --base main --head $branch --title "$prTitle" --body "See changes in $branch"
    if ($LASTEXITCODE -ne 0) {
        Write-Message "Failed to create pull request. Exit code: $LASTEXITCODE" -Type Error
        return
    }
    Write-Message "Pull request created successfully" -Type Verbose
    # Open the PR in your browser
    Write-Message "Opening PR in browser" -Type Debug
    gh pr view --web
    if ($LASTEXITCODE -ne 0) {
        Write-Message "Failed to open pull request in browser. Exit code: $LASTEXITCODE" -Type Warning
    } else {
        Write-Message "Successfully opened PR in browser" -Type Debug
    }
    Write-Message "New-GitPullRequest function completed" -Type Verbose
}
