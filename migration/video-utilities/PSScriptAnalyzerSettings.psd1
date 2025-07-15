@{
    IncludeDefaultRules = $true
    Rules = @{
        # Code Style and Formatting
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }

        PSUseConsistentNaming = @{
            Enable = $true
        }

        # Variable and Function Usage
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }

        PSUseSingularNouns = @{
            Enable = $false
        }

        # Output and Logging
        PSAvoidUsingWriteHost = @{
            Enable = $true
        }

        PSUseWriteOutput = @{
            Enable = $true
        }

        # Function Design
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }

        PSUseSupportsShouldProcess = @{
            Enable = $true
        }

        # Parameter Design and Error Handling
        PSUseShouldContinueForStateChangingFunctions = @{
            Enable = $true
        }

        # Performance
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }

        PSAvoidUsingPositionalParameters = @{
            Enable = $true
        }

        # Security
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }

        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }

        # Best Practices
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @(
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core',
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'win-8_x64_10.0.14393.0_7.0.0_x64_3.1.2_core'
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
            )
        }

        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetProfiles = @(
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core',
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'win-8_x64_10.0.14393.0_7.0.0_x64_3.1.2_core'
                'win-8_x64_10.0.17763.0_7.0.0_x64_3.1.2_core'
            )
        }

        # Documentation
        PSUseUTF8EncodingForHelpFile = @{
            Enable = $true
        }

        PSUseBOMForUnicodeEncodedFile = @{
            Enable = $true
        }

        PSAvoidUsingWMICmdlet = @{
            Enable = $true  # WMI might be needed for system operations
        }

        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true  # Some error handling might be intentional
        }

        # Disable some rules that might not be appropriate for this project
        PSAvoidGlobalVars = @{
            Enable = $false  # Module-level variables are acceptable
        }
    }
    Formatting = @{
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace  = $true
            CheckOpenParen  = $true
            CheckOperator   = $true
            CheckPipe       = $true
        }

        AssignmentOperatorAlignment = 'None'
    }
}