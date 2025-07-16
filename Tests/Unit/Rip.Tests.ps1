Describe 'Rip Module' {
    BeforeAll {
        # Import the entire Rip module
        Import-Module '.\Modules\Rip\RipTools.psm1' -Force
    }
    # Import individual function tests
    # TODO: Add Rip function tests as they are created
    # . "$PSScriptRoot\Rip\Convert-VideoFiles.Tests.ps1"
    # . "$PSScriptRoot\Rip\Invoke-BonusContentProcessing.Tests.ps1"
    # . "$PSScriptRoot\Rip\Invoke-DvdProcessing.Tests.ps1"
    # . "$PSScriptRoot\Rip\Invoke-HandbrakeConversion.Tests.ps1"
    # . "$PSScriptRoot\Rip\Invoke-RemuxProcessing.Tests.ps1"
    # . "$PSScriptRoot\Rip\Invoke-SeasonScan.Tests.ps1"
}
