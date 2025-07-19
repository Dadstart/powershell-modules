@{
    # Include default rules and custom rule sets
    IncludeDefaultRules = $true
    # Custom rule settings
    Rules = @{
        # Code formatting and style
        PSAlignAssignmentStatement = @{
            Enable = $false
            # CheckHashtable = $true
            # CheckNewLine = $true
        }
        PSAvoidLongLines = @{
            Enable = $true
            MaximumLineLength = 200
        }
        PSAvoidTrailingWhitespace = @{
            Enable = $true
        }
        PSProvideCommentHelp = @{
            Enable = $true
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = 'begin'
        }
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
            # OTBS (One True Brace Style) configuration
            OpenBraceOnSameLine = $true
            OpenBraceOnSameLineAsControlStatement = $true
            OpenBraceOnSameLineAsKeyword = $true
        }
        # Naming conventions
        PSAvoidDefaultValueForMandatoryParameter = @{
            Enable = $true
        }
        PSAvoidDefaultValueSwitchParameter = @{
            Enable = $true
        }
        PSAvoidInvokingEmptyMembers = @{
            Enable = $true
        }
        PSAvoidNullOrEmptyHelpMessage = @{
            Enable = $true
        }
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            # Allow common aliases that are widely accepted
            Whitelist = @('ls', 'cat', 'cd', 'pwd', 'echo', 'cls', 'cp', 'mv', 'rm', 'md', 'rd')
        }
        PSAvoidUsingDeprecatedManifestFields = @{
            Enable = $true
        }
        PSAvoidUsingEmptyCatchBlock = @{
            Enable = $true
        }
        PSAvoidUsingPositionalParameters = @{
            Enable = $true
            CommandAllowList = @(
                'Join-Path',
                'Get-Path',
                'Get-ChildItem',
                'Get-Item',
                'Get-ItemProperty',
                'Get-ItemPropertyValue',
                'Get-ItemType',
                'Get-ItemStream',
                'Get-ItemStreamReader',
                'Get-ItemStreamWriter'
                'Get-ItemStreamReader',
                'Get-ItemStreamWriter'
                )
        }
        PSAvoidUsingUsernameAndPasswordParams = @{
            Enable = $true
        }
        PSAvoidUsingWriteHost = @{
            Enable = $true
        }
        # Security and best practices
        PSAvoidGlobalAliases = @{
            Enable = $true
        }
        PSAvoidGlobalFunctions = @{
            Enable = $true
        }
        PSAvoidGlobalVars = @{
            Enable = $true
        }
        PSAvoidPlainTextPassword = @{
            Enable = $true
        }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{
            Enable = $true
        }
        PSAvoidUsingComputerNameHardcoded = @{
            Enable = $true
        }
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }
        PSAvoidUsingInvokeExpression = @{
            Enable = $true
        }
        PSAvoidUsingWMICmdlet = @{
            Enable = $true
        }
        # Performance and efficiency
        PSAvoidAssignmentToAutomaticVariable = @{
            Enable = $true
        }
        PSAvoidUsingBrokenHashAlgorithms = @{
            Enable = $true
        }
        PSAvoidUsingClearAll = @{
            Enable = $true
        }
        PSAvoidUsingContinue = @{
            Enable = $true
        }
        PSAvoidUsingDeleteMethodWithoutForce = @{
            Enable = $true
        }
        PSAvoidUsingEnum = @{
            Enable = $true
        }
        PSAvoidUsingFilter = @{
            Enable = $true
        }
        PSAvoidUsingGoto = @{
            Enable = $true
        }
        PSAvoidUsingInternalURLs = @{
            Enable = $true
        }
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        PSAvoidUsingRemoveItemWithoutRecurse = @{
            Enable = $true
        }
        PSAvoidUsingShouldContinueWithoutForce = @{
            Enable = $true
        }
        PSAvoidUsingSqlServerCmdlets = @{
            Enable = $true
        }
        PSAvoidUsingTLS12 = @{
            Enable = $true
        }
        PSAvoidUsingUnapprovedVerb = @{
            Enable = $true
        }
        PSAvoidUsingUsernameAndPasswordParams = @{
            Enable = $true
        }
        # Module and manifest specific
        PSReservedCmdletChar = @{
            Enable = $true
        }
        PSReservedParams = @{
            Enable = $true
        }
        PSShouldProcess = @{
            Enable = $true
        }
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        PSUseBOMForUnicodeEncodedFile = @{
            Enable = $true
        }
        PSUseCmdletCorrectly = @{
            Enable = $true
        }
        PSUseCompatibleCommands = @{
            Enable = $true
            TargetProfiles = @('win-8_x64_10.0.17763.0_x64_4.0.30319.42000_core', 'ubuntu_x64_18.04')
        }
        PSUseCompatibleSyntax = @{
            Enable = $true
            TargetVersions = @('7.4')
        }
        PSUseCompatibleTypes = @{
            Enable = $true
            TargetProfiles = @('win-8_x64_10.0.17763.0_x64_4.0.30319.42000_core', 'ubuntu_x64_18.04')
        }
        PSUseCorrectCasing = @{
            Enable = $true
        }
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }
        PSUseLiteralInitializerForHashtable = @{
            Enable = $true
        }
        PSUseOutputTypeCorrectly = @{
            Enable = $true
        }
        PSUsePSCredentialType = @{
            Enable = $true
        }
        PSUseProcessBlockForPipelineCommand = @{
            Enable = $true
        }
        PSUseShouldProcessForStateChangingFunctions = @{
            Enable = $true
        }
        PSUseSingularNouns = @{
            Enable = $true
        }
        PSUseSupportsShouldProcess = @{
            Enable = $true
        }
        PSUseToExportFieldsInManifest = @{
            Enable = $true
        }
        PSUseUTF8EncodingForHelpFile = @{
            Enable = $true
        }
        PSUseUsingScopeModifierInNewRunspaces = @{
            Enable = $true
        }
        PSUseVerboseMessage = @{
            Enable = $true
        }
    }
    # Custom rule paths (if you have custom rules)
    CustomRulePath = @()
    # Exclude paths
    ExcludeRules = @(
        # Temporarily exclude some rules that might be too strict for development
        'PSAvoidUsingWriteHost'  # We use Write-Message instead
    )
    # Severity levels
    Severity = @(
        'Error',
        'Warning',
        'Information'
    )
} 
