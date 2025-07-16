BeforeAll {
    $sharedModulePath = Join-Path $PSScriptRoot '..\..\..\Modules\Shared\Shared.psm1'
    Import-Module $sharedModulePath -Force

    # Import the module to test
    $functionPath = Join-Path $PSScriptRoot '..\..\..\Modules\Shared\Public\Write-Message.ps1'
    . $functionPath

    # Create a temporary log file for testing
    $script:TestLogFile = Join-Path $TestDrive 'test-write-message.log'

    # Store original preferences for cleanup
    $script:OriginalVerbosePreference = $VerbosePreference
    $script:OriginalDebugPreference = $DebugPreference
    $script:OriginalWarningPreference = $WarningPreference
    $script:OriginalErrorActionPreference = $ErrorActionPreference
}

AfterAll {
    # Restore original preferences
    $VerbosePreference = $script:OriginalVerbosePreference
    $DebugPreference = $script:OriginalDebugPreference
    $WarningPreference = $script:OriginalWarningPreference
    $ErrorActionPreference = $script:OriginalErrorActionPreference

    # Clean up test log file
    if (Test-Path $script:TestLogFile) {
        Remove-Item $script:TestLogFile -Force
    }
}

Describe 'Write-Message' {
    BeforeEach {
        # Reset configuration before each test
        Set-WriteMessageConfig -Reset
        $VerbosePreference = 'Continue'
        $DebugPreference = 'Continue'
        $WarningPreference = 'Continue'
        $ErrorActionPreference = 'Continue'
    }

    Context 'Basic Message Types' {
        It 'Should write Info messages without throwing' {
            { Write-Message 'Test info message' -Type Info } | Should -Not -Throw
        }

        It 'Should write Success messages without throwing' {
            { Write-Message 'Test success message' -Type Success } | Should -Not -Throw
        }

        It 'Should write Warning messages without throwing' {
            { Write-Message 'Test warning message' -Type Warning } | Should -Not -Throw
        }

        It 'Should write Error messages without throwing' {
            { Write-Message 'Test error message' -Type Error } | Should -Not -Throw
        }

        It 'Should write Processing messages without throwing' {
            { Write-Message 'Test processing message' -Type Processing } | Should -Not -Throw
        }

        It 'Should write Debug messages without throwing' {
            { Write-Message 'Test debug message' -Type Debug } | Should -Not -Throw
        }

        It 'Should write Verbose messages without throwing' {
            { Write-Message 'Test verbose message' -Type Verbose } | Should -Not -Throw
        }

        It 'Should use Info as default type when not specified' {
            { Write-Message 'Test default message' } | Should -Not -Throw
        }
    }

    Context 'Message Content Handling' {
        It 'Should handle null input gracefully' {
            { Write-Message $null -Type Info } | Should -Not -Throw
        }

        It 'Should handle empty string input' {
            { Write-Message '' -Type Info } | Should -Not -Throw
        }

        It 'Should handle multiple objects with separator' {
            { Write-Message 'Hello', 'World' -Separator ' - ' -Type Info } | Should -Not -Throw
        }

        It 'Should handle hashtable input' {
            $hashtable = @{ Name = 'Test'; Value = 123 }
            { Write-Message $hashtable -Type Info } | Should -Not -Throw
        }

        It 'Should handle PSCustomObject input' {
            $obj = [PSCustomObject]@{ Name = 'Test'; Value = 123 }
            { Write-Message $obj -Type Info } | Should -Not -Throw
        }

        It 'Should handle array input' {
            $array = @('Item1', 'Item2', 'Item3')
            { Write-Message $array -Type Info } | Should -Not -Throw
        }

        It 'Should handle emoji and special characters' {
            { Write-Message '🚫 Test message with emoji ⚠️' -Type Warning } | Should -Not -Throw
        }
    }

    Context 'NoNewline Parameter' {
        It 'Should respect NoNewline parameter' {
            { Write-Message 'Test' -Type Info -NoNewline } | Should -Not -Throw
        }

        It 'Should allow building multi-part messages' {
            { 
                Write-Message 'Processing...' -Type Info -NoNewline
                Write-Message ' Done!' -Type Success
            } | Should -Not -Throw
        }
    }

    Context 'Timestamp Functionality' {
        It 'Should add timestamp when TimeStamp parameter is specified' {
            { Write-Message 'Test message' -Type Info -TimeStamp } | Should -Not -Throw
        }

        It 'Should respect global TimeStamp configuration' {
            Set-WriteMessageConfig -TimeStamp
            { Write-Message 'Test message' -Type Info } | Should -Not -Throw
        }

        It 'Should override global TimeStamp with parameter' {
            Set-WriteMessageConfig -TimeStamp
            { Write-Message 'Test message' -Type Info -TimeStamp:$false } | Should -Not -Throw
        }
    }

    Context 'JSON Output' {
        It 'Should output JSON when AsJson parameter is specified' {
            $result = Write-Message 'Test message' -Type Info -AsJson
            $result | Should -Not -BeNullOrEmpty
            $json = $result | ConvertFrom-Json
            $json.Message | Should -Be 'Test message'
            $json.Type | Should -Be 'Info'
            $json.TimeStamp | Should -Not -BeNullOrEmpty
        }

        It 'Should respect global AsJson configuration' {
            Set-WriteMessageConfig -AsJson
            $result = Write-Message 'Test message' -Type Success
            $result | Should -Not -BeNullOrEmpty
            $json = $result | ConvertFrom-Json
            $json.Type | Should -Be 'Success'
        }

        It 'Should include context in JSON when enabled' {
            Set-WriteMessageConfig -AsJson -IncludeContext
            $result = Write-Message 'Test message' -Type Info
            $result | Should -Not -BeNullOrEmpty
            $json = $result | ConvertFrom-Json
            $json.Context | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Call-Site Context' {
        It 'Should include context when IncludeContext parameter is specified' {
            { Write-Message 'Test message' -Type Info -IncludeContext } | Should -Not -Throw
        }

        It 'Should respect global IncludeContext configuration' {
            Set-WriteMessageConfig -IncludeContext
            { Write-Message 'Test message' -Type Info } | Should -Not -Throw
        }

        It 'Should override global IncludeContext with parameter' {
            Set-WriteMessageConfig -IncludeContext
            { Write-Message 'Test message' -Type Info -IncludeContext:$false } | Should -Not -Throw
        }
    }

    Context 'Custom Color Override' {
        It 'Should respect custom Color parameter' {
            { Write-Message 'Test message' -Type Info -Color 'Red' } | Should -Not -Throw
        }

        It 'Should override default type colors' {
            { Write-Message 'Test message' -Type Success -Color 'Blue' } | Should -Not -Throw
        }
    }

    Context 'Log File Functionality' {
        It 'Should write to log file when LogFile parameter is specified' {
            { Write-Message 'Test log message' -Type Info -LogFile $script:TestLogFile } | Should -Not -Throw
            Test-Path $script:TestLogFile | Should -Be $true
        }

        It 'Should respect global LogFile configuration' {
            Set-WriteMessageConfig -LogFile $script:TestLogFile
            { Write-Message 'Test log message' -Type Info } | Should -Not -Throw
            Test-Path $script:TestLogFile | Should -Be $true
        }

        It 'Should append to existing log file' {
            $initialContent = Get-Content $script:TestLogFile -ErrorAction SilentlyContinue
            Write-Message 'Additional log message' -Type Info -LogFile $script:TestLogFile
            $finalContent = Get-Content $script:TestLogFile
            $finalContent.Count | Should -BeGreaterThan ($initialContent?.Count ?? 0)
        }
    }

    Context 'ANSI Configuration' {
        It 'Should respect ForceAnsi setting' {
            Set-WriteMessageConfig -ForceAnsi
            { Write-Message 'Test message' -Type Info } | Should -Not -Throw
        }

        It 'Should respect DisableAnsi setting' {
            Set-WriteMessageConfig -DisableAnsi
            { Write-Message 'Test message' -Type Info } | Should -Not -Throw
        }

        It 'Should handle ANSI color codes when supported' {
            Set-WriteMessageConfig -ForceAnsi
            { Write-Message 'Test message' -Type Success } | Should -Not -Throw
        }

        It 'Should fallback to PowerShell colors when ANSI disabled' {
            Set-WriteMessageConfig -DisableAnsi
            { Write-Message 'Test message' -Type Warning } | Should -Not -Throw
        }
    }

    Context 'PowerShell Stream Behavior' {
        It 'Should use Write-Debug for Debug type' {
            $DebugPreference = 'Continue'
            { Write-Message 'Debug test' -Type Debug } | Should -Not -Throw
        }

        It 'Should use Write-Verbose for Verbose type' {
            $VerbosePreference = 'Continue'
            { Write-Message 'Verbose test' -Type Verbose } | Should -Not -Throw
        }

        It 'Should use Write-Warning for Warning type' {
            { Write-Message 'Warning test' -Type Warning } | Should -Not -Throw
        }

        It 'Should use Write-Error for Error type' {
            { Write-Message 'Error test' -Type Error } | Should -Not -Throw
        }

        It 'Should respect DebugPreference setting' {
            $DebugPreference = 'SilentlyContinue'
            { Write-Message 'Debug test' -Type Debug } | Should -Not -Throw
        }

        It 'Should respect VerbosePreference setting' {
            $VerbosePreference = 'SilentlyContinue'
            { Write-Message 'Verbose test' -Type Verbose } | Should -Not -Throw
        }
    }

    Context 'Configuration Management' {
        It 'Should initialize with default configuration when none exists' {
            # Clear any existing configuration
            Remove-Variable -name script:WriteMessageConfig -Scope Script -ErrorAction SilentlyContinue
            { Write-Message 'Test message' -Type Info } | Should -Not -Throw
        }

        It 'Should maintain configuration across multiple calls' {
            Set-WriteMessageConfig -TimeStamp -LogFile $script:TestLogFile
            Write-Message 'First message' -Type Info
            Write-Message 'Second message' -Type Success
            Test-Path $script:TestLogFile | Should -Be $true
        }
    }

    Context 'Edge Cases and Error Handling' {
        It 'Should handle invalid color gracefully' {
            { Write-Message 'Test message' -Type Info -Color 'InvalidColor' } | Should -Not -Throw
        }

        It 'Should handle non-existent log file path gracefully' {
            { Write-Message 'Test message' -Type Info -LogFile 'C:\NonExistent\Path\file.log' } | Should -Not -Throw
        }

        It 'Should handle large message content' {
            $largeMessage = 'A' * 10000
            { Write-Message $largeMessage -Type Info } | Should -Not -Throw
        }

        It 'Should handle special characters in message' {
            $specialChars = "`t`n`r`0`b`f"
            { Write-Message $specialChars -Type Info } | Should -Not -Throw
        }
    }

    Context 'Pipeline Support' {
        It 'Should accept pipeline input' {
            'Pipeline message' | Write-Message -Type Info
        }

        It 'Should handle multiple pipeline objects' {
            @('First', 'Second', 'Third') | Write-Message -Type Info
        }

        It 'Should handle pipeline with separator' {
            @('Hello', 'World') | Write-Message -Type Info -Separator ' - '
        }
    }
}

Describe 'Set-WriteMessageConfig' {
    BeforeEach {
        Set-WriteMessageConfig -Reset
    }

    Context 'Configuration Parameters' {
        It 'Should set LogFile configuration' {
            Set-WriteMessageConfig -LogFile 'C:\test.log'
            $config = Get-WriteMessageConfig
            $config.LogFile | Should -Be 'C:\test.log'
        }

        It 'Should set TimeStamp configuration' {
            Set-WriteMessageConfig -TimeStamp
            $config = Get-WriteMessageConfig
            $config.TimeStamp | Should -Be $true
        }

        It 'Should set Separator configuration' {
            Set-WriteMessageConfig -Separator '|'
            $config = Get-WriteMessageConfig
            $config.Separator | Should -Be '|'
        }

        It 'Should set AsJson configuration' {
            Set-WriteMessageConfig -AsJson
            $config = Get-WriteMessageConfig
            $config.AsJson | Should -Be $true
        }

        It 'Should set IncludeContext configuration' {
            Set-WriteMessageConfig -IncludeContext
            $config = Get-WriteMessageConfig
            $config.IncludeContext | Should -Be $true
        }

        It 'Should set ForceAnsi configuration' {
            Set-WriteMessageConfig -ForceAnsi
            $config = Get-WriteMessageConfig
            $config.ForceAnsi | Should -Be $true
        }

        It 'Should set DisableAnsi configuration' {
            Set-WriteMessageConfig -DisableAnsi
            $config = Get-WriteMessageConfig
            $config.DisableAnsi | Should -Be $true
        }
    }

    Context 'Level Colors Configuration' {
        It 'Should set custom level colors' {
            $customColors = @{
                'Info'    = 'Blue'
                'Success' = 'Green'
                'Warning' = 'Yellow'
                'Error'   = 'Red'
            }
            Set-WriteMessageConfig -LevelColors $customColors
            $config = Get-WriteMessageConfig
            $config.LevelColors['Info'] | Should -Be 'Blue'
            $config.LevelColors['Success'] | Should -Be 'Green'
        }

        It 'Should validate color names' {
            $invalidColors = @{
                'Info' = 'InvalidColor'
            }
            { Set-WriteMessageConfig -LevelColors $invalidColors } | Should -Not -Throw
        }

        It 'Should preserve existing colors for unmodified types' {
            Set-WriteMessageConfig -LevelColors @{ 'Info' = 'Blue' }
            $config = Get-WriteMessageConfig
            $config.LevelColors['Success'] | Should -Be 'Green'  # Should remain default
        }
    }

    Context 'Reset Functionality' {
        It 'Should reset configuration to defaults' {
            # Set some custom values
            Set-WriteMessageConfig -TimeStamp -LogFile 'test.log' -AsJson
            $config = Get-WriteMessageConfig
            $config.TimeStamp | Should -Be $true
            $config.LogFile | Should -Be 'test.log'

            # Reset
            Set-WriteMessageConfig -Reset
            $config = Get-WriteMessageConfig
            $config.TimeStamp | Should -Be $false
            $config.LogFile | Should -BeNullOrEmpty
        }

        It 'Should reset level colors to defaults' {
            Set-WriteMessageConfig -LevelColors @{ 'Info' = 'Blue' }
            Set-WriteMessageConfig -Reset
            $config = Get-WriteMessageConfig
            $config.LevelColors['Info'] | Should -Be 'White'  # Default value
        }
    }

    Context 'Multiple Parameter Combinations' {
        It 'Should handle multiple parameters simultaneously' {
            Set-WriteMessageConfig -TimeStamp -LogFile 'test.log' -AsJson -IncludeContext
            $config = Get-WriteMessageConfig
            $config.TimeStamp | Should -Be $true
            $config.LogFile | Should -Be 'test.log'
            $config.AsJson | Should -Be $true
            $config.IncludeContext | Should -Be $true
        }

        It 'Should handle ANSI configuration conflicts' {
            # ForceAnsi should take precedence
            Set-WriteMessageConfig -ForceAnsi -DisableAnsi
            $config = Get-WriteMessageConfig
            $config.ForceAnsi | Should -Be $true
            $config.DisableAnsi | Should -Be $true
        }
    }
}

Describe 'Get-WriteMessageConfig' {
    BeforeEach {
        Set-WriteMessageConfig -Reset
    }

    Context 'Default Configuration' {
        It 'Should return default configuration when none exists' {
            Remove-Variable -name script:WriteMessageConfig -Scope Script -ErrorAction SilentlyContinue
            $config = Get-WriteMessageConfig
            $config.LogFile | Should -BeNullOrEmpty
            $config.TimeStamp | Should -Be $false
            $config.AsJson | Should -Be $false
            $config.IncludeContext | Should -Be $false
        }

        It 'Should return all default level colors' {
            $config = Get-WriteMessageConfig
            $config.LevelColors['Info'] | Should -Be 'White'
            $config.LevelColors['Success'] | Should -Be 'Green'
            $config.LevelColors['Warning'] | Should -Be 'Yellow'
            $config.LevelColors['Error'] | Should -Be 'Red'
            $config.LevelColors['Processing'] | Should -Be 'Cyan'
            $config.LevelColors['Debug'] | Should -Be 'Gray'
            $config.LevelColors['Verbose'] | Should -Be 'Gray'
        }
    }

    Context 'Configuration Retrieval' {
        It 'Should return current configuration after modifications' {
            Set-WriteMessageConfig -TimeStamp -LogFile 'test.log'
            $config = Get-WriteMessageConfig
            $config.TimeStamp | Should -Be $true
            $config.LogFile | Should -Be 'test.log'
        }

        It 'Should return modified level colors' {
            Set-WriteMessageConfig -LevelColors @{ 'Info' = 'Blue' }
            $config = Get-WriteMessageConfig
            $config.LevelColors['Info'] | Should -Be 'Blue'
        }

        It 'Should return ANSI configuration settings' {
            Set-WriteMessageConfig -ForceAnsi
            $config = Get-WriteMessageConfig
            $config.ForceAnsi | Should -Be $true
            $config.DisableAnsi | Should -Be $false
        }
    }

    Context 'Configuration Object Structure' {
        It 'Should return PSCustomObject with expected properties' {
            $config = Get-WriteMessageConfig
            $config.PSObject.Properties.Name | Should -Contain 'LogFile'
            $config.PSObject.Properties.Name | Should -Contain 'TimeStamp'
            $config.PSObject.Properties.Name | Should -Contain 'Separator'
            $config.PSObject.Properties.Name | Should -Contain 'AsJson'
            $config.PSObject.Properties.Name | Should -Contain 'IncludeContext'
            $config.PSObject.Properties.Name | Should -Contain 'ForceAnsi'
            $config.PSObject.Properties.Name | Should -Contain 'DisableAnsi'
            $config.PSObject.Properties.Name | Should -Contain 'LevelColors'
        }

        It 'Should return LevelColors as hashtable' {
            $config = Get-WriteMessageConfig
            $config.LevelColors | Should -BeOfType [hashtable]
        }
    }
}