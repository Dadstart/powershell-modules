Describe 'Get-MediaInfo' {
    BeforeAll {
        # Import the module
        Import-Module (Join-Path $PSScriptRoot '..\..\..\Modules\Media\Media.psd1') -Force
        
        # Create test files
        $TestPath = Join-Path $TestDrive 'MediaTest'
        New-Item -Path $TestPath -ItemType Directory -Force | Out-Null
        
        # Create test media files
        $TestVideo = Join-Path $TestPath 'test_video.mp4'
        $TestAudio = Join-Path $TestPath 'test_audio.mp3'
        $TestImage = Join-Path $TestPath 'test_image.jpg'
        
        "Test video content" | Out-File -FilePath $TestVideo -Encoding UTF8
        "Test audio content" | Out-File -FilePath $TestAudio -Encoding UTF8
        "Test image content" | Out-File -FilePath $TestImage -Encoding UTF8
    }
    
    AfterAll {
        # Cleanup
        Remove-Module Media -ErrorAction SilentlyContinue
    }
    
    Context 'Parameter Validation' {
        It 'Should throw when Path is null or empty' {
            { Get-MediaInfo -Path $null } | Should -Throw
            { Get-MediaInfo -Path '' } | Should -Throw
        }
        
        It 'Should throw when Path does not exist' {
            { Get-MediaInfo -Path 'C:\NonExistentPath' } | Should -Throw
        }
        
        It 'Should accept valid MediaType values' {
            { Get-MediaInfo -Path $TestPath -MediaType 'Video' } | Should -Not -Throw
            { Get-MediaInfo -Path $TestPath -MediaType 'Audio' } | Should -Not -Throw
            { Get-MediaInfo -Path $TestPath -MediaType 'Image' } | Should -Not -Throw
            { Get-MediaInfo -Path $TestPath -MediaType 'All' } | Should -Not -Throw
        }
        
        It 'Should throw for invalid MediaType values' {
            { Get-MediaInfo -Path $TestPath -MediaType 'Invalid' } | Should -Throw
        }
    }
    
    Context 'Single File Processing' {
        It 'Should return MediaFile object for valid video file' {
            $Result = Get-MediaInfo -Path $TestVideo
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -BeOfType [MediaFile]
            $Result.MediaType | Should -Be 'Video'
            $Result.Name | Should -Be 'test_video.mp4'
        }
        
        It 'Should return MediaFile object for valid audio file' {
            $Result = Get-MediaInfo -Path $TestAudio
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -BeOfType [MediaFile]
            $Result.MediaType | Should -Be 'Audio'
            $Result.Name | Should -Be 'test_audio.mp3'
        }
        
        It 'Should return MediaFile object for valid image file' {
            $Result = Get-MediaInfo -Path $TestImage
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -BeOfType [MediaFile]
            $Result.MediaType | Should -Be 'Image'
            $Result.Name | Should -Be 'test_image.jpg'
        }
    }
    
    Context 'Directory Processing' {
        It 'Should return multiple MediaFile objects for directory' {
            $Results = Get-MediaInfo -Path $TestPath
            $Results | Should -Not -BeNullOrEmpty
            $Results.Count | Should -Be 3
            $Results | Should -BeOfType [MediaFile]
        }
        
        It 'Should filter by MediaType correctly' {
            $VideoResults = Get-MediaInfo -Path $TestPath -MediaType 'Video'
            $VideoResults.Count | Should -Be 1
            $VideoResults[0].MediaType | Should -Be 'Video'
            
            $AudioResults = Get-MediaInfo -Path $TestPath -MediaType 'Audio'
            $AudioResults.Count | Should -Be 1
            $AudioResults[0].MediaType | Should -Be 'Audio'
            
            $ImageResults = Get-MediaInfo -Path $TestPath -MediaType 'Image'
            $ImageResults.Count | Should -Be 1
            $ImageResults[0].MediaType | Should -Be 'Image'
        }
    }
    
    Context 'MediaFile Properties' {
        It 'Should have correct basic properties' {
            $Result = Get-MediaInfo -Path $TestVideo
            
            $Result.Path | Should -Be $TestVideo
            $Result.Name | Should -Be 'test_video.mp4'
            $Result.Extension | Should -Be '.mp4'
            $Result.Size | Should -BeGreaterThan 0
            $Result.Created | Should -Not -BeNullOrEmpty
            $Result.Modified | Should -Not -BeNullOrEmpty
            $Result.MediaType | Should -Be 'Video'
        }
        
        It 'Should have valid IsValid method' {
            $Result = Get-MediaInfo -Path $TestVideo
            $Result.IsValid() | Should -Be $true
        }
        
        It 'Should have working GetFormattedSize method' {
            $Result = Get-MediaInfo -Path $TestVideo
            $FormattedSize = $Result.GetFormattedSize()
            $FormattedSize | Should -Not -BeNullOrEmpty
            $FormattedSize | Should -Match '^\d+\.\d+ [KMGT]?B$'
        }
    }
    
    Context 'Error Handling' {
        It 'Should handle non-media files gracefully' {
            $NonMediaFile = Join-Path $TestPath 'test.txt'
            "Test content" | Out-File -FilePath $NonMediaFile -Encoding UTF8
            
            $Result = Get-MediaInfo -Path $NonMediaFile
            $Result.MediaType | Should -Be 'Unknown'
            $Result.IsValid() | Should -Be $false
        }
    }
} 