function prompt {
    $path = Get-Location
    $leaf = Split-Path -Path $path -Leaf
    $repoName = ''
    $branchName = ''

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
               ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    try {
        $gitRoot = git -C $path rev-parse --show-toplevel 2>$null
        if ($gitRoot) {
            $repoName = Split-Path $gitRoot -Leaf
            $branchName = git -C $gitRoot rev-parse --abbrev-ref HEAD 2>$null
        }
    } catch {
        # Not in a Git repo—nothing to do
    }

    if ($repoName -and $branchName) {
        $title = "[$repoName`:$branchName]`: $leaf"
        $prompt = "PS [$repoName`:$branchName]`: $path>"
    } else {
        $title = "$leaf"
        $prompt = "PS $path>"
    }

    if ($isAdmin) {
        $title = "Admin: $title"
    }

    $host.UI.RawUI.WindowTitle = $title
    $prompt
}
