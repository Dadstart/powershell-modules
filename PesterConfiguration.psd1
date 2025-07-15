@{
    Run = @{
        Path = 'Tests'
        ExcludePath = @(
            'Tests\Integration'
            'Tests\Performance'
        )
        TestExtension = '.Tests.ps1'
        CodeCoverage = @{
            Enabled = $true
            Path = @(
                'Modules\*\Public\*.ps1'
                'Modules\*\Private\*.ps1'
                'Modules\*\Classes\*.ps1'
            )
            ExcludeTests = $true
            OutputFormat = 'JaCoCo'
            OutputPath = 'BuildOutput\CodeCoverage.xml'
        }
    }
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = 'BuildOutput\TestResults.xml'
    }
    Output = @{
        Verbosity = 'Detailed'
    }
    Should = @{
        ErrorAction = 'Continue'
    }
} 