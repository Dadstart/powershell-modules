<#
.SYNOPSIS
    Comprehensive Pester tests for the ScratchCore module.

.DESCRIPTION
    This test file demonstrates proper PowerShell testing practices using Pester.
    It includes unit tests, integration tests, and best practices examples.

.EXAMPLE
    Invoke-Pester -Path .\Test-ScratchCoreModule.Tests.ps1

    Runs all tests for the ScratchCore module.
#>

# Import the module for testing
$modulePath = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $modulePath "ScratchCore.psm1") -Force

Describe 'ScratchCore Module' {
    Context 'Module Loading' {
        It 'Should load without errors' {
            { Import-Module (Join-Path $modulePath "ScratchCore.psm1") -Force } | Should -Not -Throw
        }

        It 'Should export expected functions' {
            $expectedFunctions = @(
                'Write-Message',
                'Invoke-WithErrorHandling',
                'Start-ProgressActivity',
                'Test-ProgressActivity',
                'Get-EnvironmentInfo',
                'Get-Path',
                'Get-String',
                'New-ProcessingDirectory'
            )

            $exportedFunctions = (Get-Module ScratchCore).ExportedCommands.Keys
            foreach ($function in $expectedFunctions) {
                $exportedFunctions | Should -Contain $function
            }
        }

        It 'Should have a valid module manifest' {
            $manifestPath = Join-Path $modulePath "ScratchCore.psd1"
            { Test-ModuleManifest -Path $manifestPath } | Should -Not -Throw
        }
    }

    Context 'Write-Message Function' {
        BeforeAll {
            # Capture output for testing
            $script:capturedOutput = @()
        }

        It 'Should accept null input without error' {
            { Write-Message $null -Type Info } | Should -Not -Throw
        }

        It 'Should handle empty string input' {
            { Write-Message "" -Type Info } | Should -Not -Throw
        }

        It 'Should accept multiple objects' {
            { Write-Message "Hello", "World" -Type Info } | Should -Not -Throw
        }

        It 'Should validate Type parameter' {
            { Write-Message "Test" -Type InvalidType } | Should -Throw
        }

        It 'Should use correct PowerShell streams for Debug type' {
            $debugOutput = @()
            $originalDebugPreference = $DebugPreference
            $DebugPreference = 'Continue'
            
            try {
                # Capture debug output
                $debugOutput = & {
                    Write-Message "Debug test" -Type Debug
                } 4>&1
            }
            finally {
                $DebugPreference = $originalDebugPreference
            }
            
            $debugOutput | Should -Not -BeNullOrEmpty
        }

        It 'Should use correct PowerShell streams for Verbose type' {
            $verboseOutput = @()
            $originalVerbosePreference = $VerbosePreference
            $VerbosePreference = 'Continue'
            
            try {
                # Capture verbose output
                $verboseOutput = & {
                    Write-Message "Verbose test" -Type Verbose
                } 4>&1
            }
            finally {
                $VerbosePreference = $originalVerbosePreference
            }
            
            $verboseOutput | Should -Not -BeNullOrEmpty
        }

        It 'Should use correct PowerShell streams for Warning type' {
            $warningOutput = @()
            
            # Capture warning output
            $warningOutput = & {
                Write-Message "Warning test" -Type Warning
            } 3>&1
            
            $warningOutput | Should -Not -BeNullOrEmpty
        }

        It 'Should use correct PowerShell streams for Error type' {
            $errorOutput = @()
            
            # Capture error output
            $errorOutput = & {
                Write-Message "Error test" -Type Error
            } 2>&1
            
            $errorOutput | Should -Not -BeNullOrEmpty
        }

        It 'Should handle NoNewline parameter' {
            { Write-Message "Test" -Type Info -NoNewline } | Should -Not -Throw
        }

        It 'Should handle custom separator' {
            { Write-Message "Hello", "World" -Type Info -Separator " | " } | Should -Not -Throw
        }
    }

    Context 'Get-Path Function' {
        BeforeAll {
            $testDir = Join-Path $TestDrive "GetPathTest"
            New-Item -ItemType Directory -Path $testDir -Force | Out-Null
            Set-Location $testDir
        }

        AfterAll {
            if (Test-Path $testDir) {
                Remove-Item $testDir -Recurse -Force
            }
        }

        It 'Should require Path parameter' {
            { Get-Path } | Should -Throw
        }

        It 'Should validate PathType parameter' {
            { Get-Path -Path "test" -PathType Invalid } | Should -Throw
        }

        It 'Should validate Create parameter' {
            { Get-Path -Path "test" -Create Invalid } | Should -Throw
        }

        It 'Should validate ValidatePath parameter' {
            { Get-Path -Path "test" -ValidatePath Invalid } | Should -Throw
        }

        It 'Should validate ValidationErrorAction parameter' {
            { Get-Path -Path "test" -ValidationErrorAction Invalid } | Should -Throw
        }

        It 'Should not allow both Create and ValidatePath' {
            { Get-Path -Path "test" -Create Directory -ValidatePath File } | Should -Throw
        }

        It 'Should return parent directory when PathType is Parent' {
            $result = Get-Path -Path "C:\folder\subfolder\file.txt" -PathType Parent
            $result | Should -Be "C:\folder\subfolder"
        }

        It 'Should return absolute path when PathType is Absolute' {
            $testPath = "testfile.txt"
            $result = Get-Path -Path $testPath -PathType Absolute
            $expected = [System.IO.Path]::GetFullPath($testPath)
            $result | Should -Be $expected
        }

        It 'Should return leaf name when PathType is Leaf' {
            $result = Get-Path -Path "C:\folder\subfolder\file.txt" -PathType Leaf
            $result | Should -Be "file.txt"
        }

        It 'Should return leaf base when PathType is LeafBase' {
            $result = Get-Path -Path "C:\folder\subfolder\file.txt" -PathType LeafBase
            $result | Should -Be "file"
        }

        It 'Should return extension when PathType is Extension' {
            $result = Get-Path -Path "C:\folder\subfolder\file.txt" -PathType Extension
            $result | Should -Be ".txt"
        }

        It 'Should return qualifier when PathType is Qualifier' {
            $result = Get-Path -Path "C:\folder\subfolder\file.txt" -PathType Qualifier
            $result | Should -Be "C:\"
        }

        It 'Should return no qualifier when PathType is NoQualifier' {
            $result = Get-Path -Path "C:\folder\subfolder\file.txt" -PathType NoQualifier
            $result | Should -Be "folder\subfolder\file.txt"
        }

        It 'Should combine multiple path components' {
            $result = Get-Path -Path "folder", "subfolder", "file.txt" -PathType Absolute
            $expected = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine("folder", "subfolder", "file.txt"))
            $result | Should -Be $expected
        }

        It 'Should create directory when Create is Directory' {
            $testDirPath = Join-Path $TestDrive "NewTestDir"
            $result = Get-Path -Path $testDirPath -PathType Absolute -Create Directory
            Test-Path $testDirPath -PathType Container | Should -Be $true
            $result | Should -Be $testDirPath
        }

        It 'Should create file when Create is File' {
            $testFilePath = Join-Path $TestDrive "NewTestFile.txt"
            $result = Get-Path -Path $testFilePath -PathType Absolute -Create File
            Test-Path $testFilePath -PathType Leaf | Should -Be $true
            $result | Should -Be $testFilePath
        }

        It 'Should validate file exists when ValidatePath is File' {
            $testFile = Join-Path $TestDrive "ExistingFile.txt"
            New-Item -ItemType File -Path $testFile -Force | Out-Null
            
            $result = Get-Path -Path $testFile -ValidatePath File
            $result | Should -Be $testFile
        }

        It 'Should throw when validating non-existent file' {
            $nonExistentFile = Join-Path $TestDrive "NonExistentFile.txt"
            { Get-Path -Path $nonExistentFile -ValidatePath File } | Should -Throw
        }

        It 'Should return null when validation fails with Continue action' {
            $nonExistentFile = Join-Path $TestDrive "NonExistentFile.txt"
            $result = Get-Path -Path $nonExistentFile -ValidatePath File -ValidationErrorAction Continue
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle Unix-style paths' {
            $result = Get-Path -Path "/home/user/file.txt" -PathType Leaf
            $result | Should -Be "file.txt"
        }

        It 'Should handle paths without extension' {
            $result = Get-Path -Path "C:\folder\file" -PathType Extension
            $result | Should -Be ""
        }
    }

    Context 'Get-String Function' {
        It 'Should convert null to empty string' {
            $result = Get-String -Object $null
            $result | Should -Be ""
        }

        It 'Should convert single string' {
            $result = Get-String -Object "Hello"
            $result | Should -Be "Hello"
        }

        It 'Should join multiple objects with default separator' {
            $result = Get-String -Object "Hello", "World"
            $result | Should -Be "Hello World"
        }

        It 'Should use custom separator' {
            $result = Get-String -Object "Hello", "World" -Separator " | "
            $result | Should -Be "Hello | World"
        }

        It 'Should handle empty array' {
            $result = Get-String -Object @()
            $result | Should -Be ""
        }

        It 'Should handle mixed types' {
            $result = Get-String -Object "Hello", 123, $true
            $result | Should -Be "Hello 123 True"
        }
    }

    Context 'Start-ProgressActivity Function' {
        It 'Should create progress activity object' {
            $progress = Start-ProgressActivity -Activity "Test Activity" -Status "Starting..." -TotalItems 10
            $progress | Should -Not -BeNullOrEmpty
            $progress | Should -HaveProperty 'Update'
            $progress | Should -HaveProperty 'Stop'
        }

        It 'Should require Activity parameter' {
            { Start-ProgressActivity -Status "Test" -TotalItems 10 } | Should -Throw
        }

        It 'Should require Status parameter' {
            { Start-ProgressActivity -Activity "Test" -TotalItems 10 } | Should -Throw
        }

        It 'Should require TotalItems parameter' {
            { Start-ProgressActivity -Activity "Test" -Status "Test" } | Should -Throw
        }

        It 'Should validate TotalItems is positive' {
            { Start-ProgressActivity -Activity "Test" -Status "Test" -TotalItems 0 } | Should -Throw
            { Start-ProgressActivity -Activity "Test" -Status "Test" -TotalItems -1 } | Should -Throw
        }

        It 'Should update progress correctly' {
            $progress = Start-ProgressActivity -Activity "Test Activity" -Status "Starting..." -TotalItems 10
            
            # Test update
            { $progress.Update(@{ CurrentItem = 5; Status = "Processing..." }) } | Should -Not -Throw
            
            # Test stop
            { $progress.Stop(@{ Status = "Completed" }) } | Should -Not -Throw
        }
    }

    Context 'Error Handling' {
        It 'Should handle errors gracefully in Write-Message' {
            { Write-Message "Test" -Type Error } | Should -Not -Throw
        }

        It 'Should handle errors gracefully in Get-Path' {
            { Get-Path -Path "C:\nonexistent\path" -ValidatePath File -ValidationErrorAction Continue } | Should -Not -Throw
        }
    }

    Context 'Performance' {
        It 'Should handle large inputs efficiently' {
            $largeArray = 1..1000
            $startTime = Get-Date
            
            $result = Get-String -Object $largeArray
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalMilliseconds
            
            $duration | Should -BeLessThan 1000  # Should complete in less than 1 second
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle multiple progress activities' {
            $activities = @()
            
            for ($i = 1; $i -le 5; $i++) {
                $activities += Start-ProgressActivity -Activity "Activity $i" -Status "Starting..." -TotalItems 10
            }
            
            $activities.Count | Should -Be 5
            
            # Clean up
            foreach ($activity in $activities) {
                $activity.Stop(@{ Status = "Completed" })
            }
        }
    }

    Context 'Cross-Platform Compatibility' {
        It 'Should handle Windows paths' {
            $result = Get-Path -Path "C:\folder\file.txt" -PathType Leaf
            $result | Should -Be "file.txt"
        }

        It 'Should handle Unix paths' {
            $result = Get-Path -Path "/home/user/file.txt" -PathType Leaf
            $result | Should -Be "file.txt"
        }

        It 'Should handle relative paths' {
            $result = Get-Path -Path "folder\file.txt" -PathType Absolute
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Integration Tests' {
    Context 'Module Integration' {
        It 'Should work together seamlessly' {
            # Test Write-Message with Get-Path
            $testPath = "testfile.txt"
            $absolutePath = Get-Path -Path $testPath -PathType Absolute
            
            { Write-Message "Path: $absolutePath" -Type Info } | Should -Not -Throw
            
            # Test progress with Write-Message
            $progress = Start-ProgressActivity -Activity "Integration Test" -Status "Testing..." -TotalItems 3
            
            for ($i = 1; $i -le 3; $i++) {
                $progress.Update(@{ CurrentItem = $i; Status = "Processing item $i" })
                { Write-Message "Processing item $i" -Type Processing } | Should -Not -Throw
            }
            
            $progress.Stop(@{ Status = "Completed" })
        }
    }
}

Describe 'Edge Cases' {
    Context 'Boundary Conditions' {
        It 'Should handle empty strings in Write-Message' {
            { Write-Message "" -Type Info } | Should -Not -Throw
        }

        It 'Should handle very long paths in Get-Path' {
            $longPath = "a" * 260  # Windows MAX_PATH
            { Get-Path -Path $longPath -PathType Absolute } | Should -Not -Throw
        }

        It 'Should handle special characters in paths' {
            $specialPath = "C:\folder with spaces\file (1).txt"
            $result = Get-Path -Path $specialPath -PathType Leaf
            $result | Should -Be "file (1).txt"
        }
    }
} 