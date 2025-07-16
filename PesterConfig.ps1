$config = New-PesterConfiguration

$config.Run.Path = @('Tests')
$config.Run.ExcludePath = @('Tests\Integration', 'Tests\Performance')

$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = 'BuildOutput\TestResults.xml'
$config.TestResult.OutputFormat = 'NUnitXml'

$config.Output.Verbosity = 'Detailed'

$config.Should = @{ ErrorAction = 'Continue' }

$config.CodeCoverage = @{
    Enabled      = $true
    Path         = @('Modules\*\Public\*.ps1', 'Modules\*\Private\*.ps1', 'Modules\*\Classes\*.ps1')
    ExcludeTests = $true
    OutputFormat = 'JaCoCo'
    OutputPath   = 'BuildOutput\CodeCoverage.xml'
}

return $config