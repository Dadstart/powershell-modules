Describe 'Git Module' {
    BeforeAll {
        # Import the entire Git module
        Import-Module '.\Modules\Git\GitTools.psm1' -Force
    }
    # Import individual function tests
    # TODO: Add Git function tests as they are created
    # . "$PSScriptRoot\Git\Move-GitDirectory.Tests.ps1"
    # . "$PSScriptRoot\Git\New-GitCommit.Tests.ps1"
    # . "$PSScriptRoot\Git\New-GitPullRequest.Tests.ps1"
}
