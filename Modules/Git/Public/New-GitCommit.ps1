function New-GitCommit {
    <#
.SYNOPSIS
    Create a Git commit with branch management and optional pull request creation.
.DESCRIPTION
    This function stashes changes, updates main, creates a new branch, adds files, commits, pushes, and optionally opens a pull request.
.PARAMETER BranchName
    The name of the branch to create or switch to.
.PARAMETER Files
    Array of files to add to the commit.
.PARAMETER CommitMessage
    The commit message (mandatory).
.PARAMETER PRTitle
    The title for the pull request.
.PARAMETER PRBody
    The body for the pull request.
.EXAMPLE
    New-GitCommit -CommitMessage "Add new feature" -BranchName "feature/new-feature"
    Creates a new branch and commits with the specified message.
.NOTES
    This function should be run from within a git repository.
#>
    [CmdletBinding()]
    param(
        [string]$BranchName,
        [string[]]$Files,
        [Parameter(Mandatory = $true)]
        [string]$CommitMessage,
        [string]$PRTitle,
        [string]$PRBody
    )
    @(
        'Write-Message',
        'Start-ProgressActivity',
        'Get-Path',
        'Invoke-CheckedCommand',
        'Stash-Changes',
        'Switch-To-Main-And-Pull',
        'Create-And-Switch-Branch',
        'Apply-Stash',
        'Prompt-For-Files',
        'Add-Files',
        'Check-Files-To-Commit',
        'Commit-Changes',
        'Push-Branch',
        'Create-PR',
        'Open-PR-In-Browser',
        'Generate-PRBody'
    ) | Set-PreferenceInheritance
    # Summary: Stash changes, update main, create a new branch, add files, commit, push, and open a PR.
    # Check if we're in a git repository
    function Test-GitRepository {
        try {
            Write-Message 'Checking if current directory is a git repository' -Type Debug
            $null = git rev-parse --show-toplevel
            Write-Message 'Git repository found' -Type Debug
            return $true
        }
        catch {
            Write-Message 'Error: Not in a git repository. Please run this function from within a git repository.' -Type Warning
            return $false
        }
    }
    function Invoke-CheckedCommand {
        param(
            [Parameter(Mandatory = $true)]
            [scriptblock]$Command,
            [Parameter(Mandatory = $true)]
            [string]$ErrorMessage
        )
        # Capture both stdout and stderr
        Write-Message "Executing command: $Command" -Type Debug
        $allOutput = & $Command 2>&1
        $stdout = $allOutput | Where-Object { $_ -is [string] }
        $stderr = $allOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
        Write-Message "STDOUT: $stdout" -Type Debug
        Write-Message "STDERR: $stderr" -Type Debug
        # Only return false if the command actually failed
        if ($LASTEXITCODE -ne 0) {
            Write-Message "Command failed with exit code: $LASTEXITCODE,`nMessage: $ErrorMessage`nDetails:`n$($stderr -join "`n")" -Type Warning
            return $false
        }
        Write-Message 'Command executed successfully' -Type Debug
        return $stdout
    }
    function Stash-Changes {
        Write-Message 'Stashing current changes' -Type Verbose
        $result = Invoke-CheckedCommand -Command { git stash } -ErrorMessage 'Failed to stash changes.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Switch-To-Main-And-Pull {
        if ($NoMain) {
            Write-Message 'Skipping switch to main and pull.' -Type Debug
            return $true
        }
        Write-Message 'Switching to main and pulling latest.' -Type Verbose
        $result1 = Invoke-CheckedCommand -Command { git checkout main } -ErrorMessage 'Failed to checkout main.'
        if ($result1 -eq $false) {
            return $false
        }
        $result2 = Invoke-CheckedCommand -Command { git pull } -ErrorMessage 'Failed to pull latest changes from main.'
        if ($result2 -eq $false) {
            return $false
        }
        return $true
    }
    function Create-And-Switch-Branch {
        $createBranch = $BranchName -ne $null
        if ($createBranch) {
            Write-Message "Creating and switching to branch: $BranchName" -Type Verbose
            $result = Invoke-CheckedCommand -Command { git switch -C $BranchName } -ErrorMessage "Failed to create/switch to branch $BranchName."
            if ($result -eq $false) {
                return $false
            }
        }
        else {
            Write-Message "Switching to branch: $BranchName" -Type Verbose
            $result = Invoke-CheckedCommand -Command { git switch -$BranchName } -ErrorMessage "Failed to switch to branch $BranchName."
            if ($result -eq $false) {
                return $false
            }
        }
        return $true
    }
    function Apply-Stash {
        Write-Message 'Applying latest stash to new branch...' -Type Verbose
        $result = Invoke-CheckedCommand -Command { git stash apply } -ErrorMessage 'Failed to apply stash.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Prompt-For-Files {
        Write-Message 'Listing unstaged files...' -Type Verbose
        $gitFiles = Invoke-CheckedCommand -Command { git status --porcelain } -ErrorMessage 'Failed to get git status.'
        if ($gitFiles -eq $false) {
            Write-Message 'No files to process' -Type Warning
            return @()
        }
        $staged = @($gitFiles | Where-Object { $_ -match '^[ MARCDAU!?][ MARCDAU] ' } | Where-Object { $_[0] -ne ' ' } | ForEach-Object { $_.Substring(3) })
        $unstaged = @($gitFiles | Where-Object { $_ -match '^[ MARCDAU!?][ MARCDAU?] ' } | Where-Object { $_[1] -ne ' ' } | ForEach-Object { $_.Substring(3) })
        Write-Message "Found $($staged.Count) staged files and $($unstaged.Count) unstaged files" -Type Verbose
        Write-Message "Staged files: $($staged -join ', ')" -Type Debug
        Write-Message "Unstaged files: $($unstaged -join ', ')" -Type Debug
        # Check if there are any files to work with (unstaged or staged)
        if (-not $unstaged -and -not $staged) {
            Write-Message 'No unstaged or staged files found' -Type Warning
            return @()
        }
        # If there are only staged files, inform the user and return empty array to continue
        if (-not $unstaged -and $staged) {
            Write-Message 'No unstaged files found, but there are staged files. Continuing with staged files.' -Type Warning
            return @()
        }
        # Show staged files for reference
        if ($staged) {
            Write-Message "`n✅ Staged files (will be included in commit):" -Type Success
            foreach ($file in $staged) {
                Write-Message "  • $file" -Type Info
            }
            Write-Message -Type Info
        }
        # Show unstaged files for selection
        if ($unstaged) {
            Write-Message "`n📁 Unstaged files (select by number):" -Type Processing
            for ($i = 0; $i -lt $unstaged.Count; $i++) {
                Write-Message "  $($i + 1). $($unstaged[$i])" -Type Info
            }
        }
        $selection = Read-Host "Enter the numbers of the files to add (comma separated, e.g. 1,3,5), '*' for all, or type file names separated by commas"
        Write-Message -Type Info
        Write-Message "User selection: '$selection'" -Type Debug
        Write-Message "Unstaged files count: $($unstaged.Count)" -Type Debug
        Write-Message "Unstaged files: $($unstaged -join ', ')" -Type Debug
        Write-Message "Unstaged type: $($unstaged.GetType().Name)" -Type Debug
        if ($selection -replace '\s', '' -eq '*') {
            Write-Message "Wildcard '*' detected, selecting all files." -Type Debug
            $files = $unstaged
        }
        elseif ($selection -match '^[0-9, ]+$') {
            Write-Message 'Processing numeric selection' -Type Debug
            $indices = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            Write-Message "Parsed indices: $($indices -join ', ')" -Type Debug
            $files = @()
            foreach ($index in $indices) {
                $arrayIndex = [int]$index - 1
                Write-Message "Index $index -> array index $arrayIndex" -Type Debug
                if ($arrayIndex -ge 0 -and $arrayIndex -lt $unstaged.Count) {
                    $selectedFile = $unstaged[$arrayIndex]
                    Write-Message "Selected file: $selectedFile" -Type Debug
                    $files += $selectedFile
                }
                else {
                    Write-Message "Invalid index $index (valid range: 1-$($unstaged.Count))" -Type Warning
                }
            }
        }
        else {
            Write-Message 'Processing file name selection' -Type Debug
            $files = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
        Write-Message "Selected files:`n$($files -join "`n")" -Type Verbose
        # Convert paths to be relative to current working directory if needed
        $currentDir = Get-Location
        $repoRoot = git rev-parse --show-toplevel
        Write-Message "Current directory: $($currentDir.Path)" -Type Debug
        Write-Message "Repository root: $repoRoot" -Type Debug
        $relativeFiles = @()
        # Start progress tracking for file processing
        $fileProgress = Start-ProgressActivity -Activity 'File Processing' -Status 'Processing selected files...' -TotalItems $files.Count
        $currentFile = 0
        foreach ($file in $files) {
            $currentFile++
            $fileName = [System.IO.Path]::GetFileName($file)
            $fileProgress.Update(@{
                    CurrentItem = $currentFile
                    Status      = "Processing: $fileName"
                })
            Write-Message "Processing file: $file" -Type Verbose
            if ($currentDir.Path -ne $repoRoot) {
                # We're in a subdirectory, need to adjust the path
                $fullPath = Get-Path $repoRoot, $file -PathType Absolute
                Write-Message "Full path: $fullPath" -Type Debug
                try {
                    # Use System.IO.Path::GetRelativePath which works for both existing and deleted files
                    $relativePath = [System.IO.Path]::GetRelativePath($currentDir.Path, $fullPath)
                    Write-Message "Resolved relative path: $relativePath" -Type Debug
                    $relativeFiles += $relativePath
                }
                catch {
                    Write-Message "Warning: Could not resolve path for: $fullPath`nError details: $($_.Exception.Message)`Stack trace: $($_.Exception.ScriptStackTrace)" -Type Warning
                    # Use the original file path as fallback
                    Write-Message "Falling back to original path: $file" -Type Verbose
                    $relativeFiles += $file
                }
            }
            else {
                # We're at the repo root, use the path as-is
                Write-Message "At repo root, using path as-is: $file" -Type Debug
                $relativeFiles += $file
            }
        }
        $fileProgress.Stop(@{ Status = 'File processing completed' })
        Write-Message "Final files to add: $($relativeFiles -join ', ')" -Type Debug
        return $relativeFiles
    }
    function Add-Files {
        param([string[]]$FilesToAdd)
        Write-Message "Adding files:`n$($FilesToAdd -join '`n')" -Type Verbose
        $result = Invoke-CheckedCommand -Command { git add $FilesToAdd } -ErrorMessage 'Failed to add files.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Check-Files-To-Commit {
        Write-Message 'Checking for files to commit...' -Type Verbose
        $staged = @(git status --porcelain | Where-Object { $_.Trim().StartsWith('M ') -or $_.Trim().StartsWith('A ') -or $_.Trim().StartsWith('D ') })
        if (-not $staged) {
            Write-Message 'No files staged for commit' -Type Debug
            return $false
        }
        Write-Message "Found $($staged.Count) staged files:`n" -Type Verbose
        $stagedFileNames = foreach ($file in $staged) {
            $status = $file.Substring(0, 2)
            $filename = $file.Substring(3)
            "$status $filename"
        }
        Write-Message "Files staged for commit:`n$($stagedFileNames -join "`n")" -Type Verbose
        return $true
    }
    function Commit-Changes {
        Write-Message "Committing with message: $CommitMessage" -Type Verbose
        $result = Invoke-CheckedCommand -Command { git commit -m "$CommitMessage" } -ErrorMessage 'Failed to commit changes.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Push-Branch {
        Write-Message 'Pushing branch to remote' -Type Verbose
        $result = Invoke-CheckedCommand -Command { git push --force --set-upstream origin $BranchName } -ErrorMessage 'Failed to push branch to remote.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Create-PR {
        param([string]$Title, [string]$Body)
        Write-Message "Creating PR with title: $Title" -Type Verbose
        $result = Invoke-CheckedCommand -Command { gh pr create --base main --head $BranchName --title "$Title" --body "$Body" } -ErrorMessage 'Failed to create PR.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Open-PR-In-Browser {
        Write-Message 'Opening PR in browser' -Type Verbose
        $result = Invoke-CheckedCommand -Command { gh pr view --web } -ErrorMessage 'Failed to open PR in browser.'
        if ($result -eq $false) {
            return $false
        }
        return $true
    }
    function Generate-PRBody {
        Write-Message 'Generating PR body' -Type Debug
        # Get the last commit that was merged to main
        $lastMainCommit = git merge-base HEAD main
        Write-Message "Last main commit: $lastMainCommit" -Type Debug
        # Get all commits since the last merge to main
        $commits = git log --oneline "$lastMainCommit..HEAD"
        Write-Message "Found $($commits.Count) commits since last main merge" -Type Debug
        # Get all files changed since the last merge to main
        $files = git diff --name-only "$lastMainCommit..HEAD"
        Write-Message "Found $($files.Count) files changed since last main merge" -Type Debug
        $commitLines = $commits | ForEach-Object { "• $_" } | Out-String
        $fileLines = $files | ForEach-Object { "• $_" } | Out-String
        $body = @"
## Summary
This PR includes the following changes:
## Commits
$commitLines
## Files Changed
$fileLines
"@
        Write-Message "Generated PR body length: $($body.Length) characters" -Type Debug
        return $body
    }
    $index = 1;
    # Main execution logic
    Write-Message 'Starting steps to create a new Git PR' -Type Processing
    $progress = Start-ProgressActivity -Activity 'New-GitCommit' -Status 'Starting steps to create a new Git PR' -TotalItems 10
    Write-Message 'Starting New-GitCommit function' -Type Debug
    if (-not (Test-GitRepository)) {
        return
    }
    $progress.Update(@{ CurrentItem = $index; Status = 'Stashing changes' })
    Write-Message "$index`: Stashing changes" -Type Info
    Write-Message 'Stashing changes (Stash-Changes)' -Type Verbose
    $result = Stash-Changes
    if ($result -eq $false) {
        Write-Message 'Failed to stash changes' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Switching to main and pulling' })
    Write-Message "$index`: Switching to main and pulling" -Type Info
    Write-Message 'Switching to main and pulling (Switch-To-Main-And-Pull)' -Type Verbose
    $result = Switch-To-Main-And-Pull
    if ($result -eq $false) {
        Write-Message 'Failed to switch to main and pull' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Creating and switching branch' })
    Write-Message "$index`: Creating and switching branch" -Type Info
    Write-Message 'Creating and switching branch (Create-And-Switch-Branch)' -Type Verbose
    $result = Create-And-Switch-Branch
    if ($result -eq $false) {
        Write-Message 'Failed to create and switch branch' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Applying stash' })
    Write-Message "$index`: Applying stash" -Type Info
    Write-Message 'Applying stash (Apply-Stash)' -Type Verbose
    $result = Apply-Stash | Out-Null
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Prompting for files' })
    Write-Message "$index`: Prompting for files" -Type Info
    Write-Message 'Prompting for files (Prompt-For-Files)' -Type Verbose
    $Files = Prompt-For-Files
    if ((-not $files) -or ($files.Count -eq 0)) {
        Write-Message 'No files to process' -Type Verbose
        return
    }
    $index++
    Write-Message "Files to process:`n$($Files -join '`n')" -Type Verbose
    $progress.Update(@{ CurrentItem = $index; Status = 'Adding files' })
    Write-Message "$index`: Adding files" -Type Info
    Write-Message 'Adding files (Add-Files)' -Type Verbose
    $result = Add-Files -FilesToAdd $Files
    if ($result -eq $false) {
        Write-Message 'Failed to add files' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Checking files to commit' })
    Write-Message "$index`: Checking files to commit" -Type Info
    Write-Message 'Checking files to commit (Check-Files-To-Commit)' -Type Verbose
    $result = Check-Files-To-Commit
    if ($result -eq $false) {
        Write-Message 'Failed to check files to commit' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Committing changes' })
    Write-Message "$index`: Committing changes" -Type Info
    Write-Message 'Committing changes (Commit-Changes)' -Type Verbose
    $result = Commit-Changes
    if ($result -eq $false) {
        Write-Message 'Failed to commit changes' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Pushing branch' })
    Write-Message "$index`: Pushing branch" -Type Info
    Write-Message 'Pushing branch (Push-Branch)' -Type Verbose
    $result = Push-Branch
    if ($result -eq $false) {
        Write-Message 'Failed to push branch' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Creating PR Title and Body' })
    Write-Message "$index`: Creating PR Title and Body" -Type Info
    Write-Message 'Creating PR Title and Body (Create-PR)' -Type Verbose
    if ([string]::IsNullOrWhiteSpace($PRTitle)) {
        $prTitle = $CommitMessage
        Write-Message "Using commit message as PR title: $prTitle" -Type Debug
    }
    else {
        $prTitle = $PRTitle
        Write-Message "Using provided PR title: $prTitle" -Type Debug
    }
    if ([string]::IsNullOrWhiteSpace($PRBody)) {
        $prBody = Generate-PRBody
        Write-Message 'Generated PR body' -Type Debug
    }
    else {
        $prBody = $PRBody
        Write-Message 'Using provided PR body' -Type Debug
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Creating PR' })
    Write-Message "$index`: Creating PR" -Type Info
    Write-Message 'Creating PR (Create-PR)' -Type Verbose
    $result = Create-PR -Title $prTitle -Body $prBody
    if ($result -eq $false) {
        Write-Message 'Failed to create PR' -Type Error
        return
    }
    $index++
    $progress.Update(@{ CurrentItem = $index; Status = 'Opening PR in browser' })
    Write-Message "$index`: Opening PR in browser" -Type Info
    Write-Message 'Opening PR in browser (Open-PR-In-Browser)' -Type Verbose
    $result = Open-PR-In-Browser
    if ($result -eq $false) {
        Write-Message 'Failed to open PR in browser' -Type Error
        return
    }
    $index++
    $progress.Stop(@{ Status = 'New-GitCommit function completed successfully' })
    Write-Message 'New-GitCommit function completed successfully' -Type Success
}
