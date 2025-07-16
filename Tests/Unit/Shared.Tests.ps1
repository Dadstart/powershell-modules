Describe 'Shared Module' {
    BeforeAll {
        # Import the entire Shared module
        Import-Module '.\Modules\Shared\Shared.psm1' -Force
    }
    # Import individual function tests
    . "$PSScriptRoot\Shared\Write-Message.Tests.ps1"
    # TODO: Add other Shared function tests as they are created
    # . "$PSScriptRoot\Shared\Get-EnvironmentInfo.Tests.ps1"
    # . "$PSScriptRoot\Shared\Get-Path.Tests.ps1"
    # . "$PSScriptRoot\Shared\Get-String.Tests.ps1"
    # . "$PSScriptRoot\Shared\Invoke-WithErrorHandling.Tests.ps1"
    # . "$PSScriptRoot\Shared\New-ProcessingDirectory.Tests.ps1"
    # . "$PSScriptRoot\Shared\Set-PreferenceInheritance.Tests.ps1"
    # . "$PSScriptRoot\Shared\Start-ProgressActivity.Tests.ps1"
}
