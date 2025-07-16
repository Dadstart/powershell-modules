param (
    [Parameter()]
    [switch]
    $CodeCoverage,
    [Parameter()]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]
    $Verbosity
)

$config = New-PesterConfiguration

$config.Run.Path = @('Tests')
$config.Run.ExcludePath = @('Tests\Integration', 'Tests\Performance')

$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = 'BuildOutput\TestResults.xml'
$config.TestResult.OutputFormat = 'NUnitXml'

# Set verbosity based on whether code coverage is enabled
if ($Verbosity) {
    $config.Output.Verbosity = $Verbosity
} else {
    $config.Output.Verbosity = 'Normal'
}

$config.Should = @{ ErrorAction = 'Continue' }

if ($CodeCoverage) {
    $config.CodeCoverage = @{
        Enabled      = $true
        Path         = @('Modules\*\Public\*.ps1', 'Modules\*\Private\*.ps1', 'Modules\*\Classes\*.ps1')
        ExcludeTests = $true
        OutputFormat = 'JaCoCo'
        OutputPath   = 'BuildOutput\CodeCoverage.xml'
        Show         = $false
    }
}

return $config