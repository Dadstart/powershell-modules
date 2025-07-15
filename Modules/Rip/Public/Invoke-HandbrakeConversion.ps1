function Invoke-HandbrakeConversion {
    <#
    .SYNOPSIS
        Converts video files using HandBrake with audio stream management and metadata updates.
    
    .DESCRIPTION
        Processes video files in the input directory, converts them using HandBrake with appropriate audio encoding,
        and renames audio streams to match their type (Surround 5.1, Stereo, Mono). Files with multiple audio
        streams of the same language are skipped.
    
    .PARAMETER Path
        The directory containing input video files to process.
    
    .PARAMETER Destination
        The directory where converted files will be saved.
    
    .PARAMETER Language
        The language code for audio streams to process. Default is 'eng'.
    
    .EXAMPLE
        Invoke-HandbrakeConversion -Path "C:\Input" -Destination "C:\Output"
    
    .EXAMPLE
        Invoke-HandbrakeConversion -Path "C:\Input" -Destination "C:\Output" -Language "spa"
    
    .EXAMPLE
        Get-ChildItem "C:\Videos" -Directory | Invoke-HandbrakeConversion -Destination "C:\Converted"
    
    .NOTES
        This function requires the Video module to be installed and available.
        Files with multiple audio streams of the same language will be skipped.
    
    .LINK
        https://github.com/dadstart/video-modules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Language = 'eng'
    )

    begin {
        # Set default parameters for called functions
        Set-DefaultParameters
        
        Write-Message 'Starting HandBrake conversion process' -Type Verbose
        Write-Message "Invoke-HandbrakeConversion: Input directory: $Path" -Type Verbose
        Write-Message "Invoke-HandbrakeConversion: Output directory: $Destination" -Type Verbose
        Write-Message "Invoke-HandbrakeConversion: Language: $Language" -Type Verbose
    }

    process {

        $Path = Get-Path -Path $Path -PathType Absolute -ValidatePath Directory
        $Destination = New-ProcessingDirectory -Path $Destination -Description 'HandBrake output' -SuppressOutput

        Write-Message "Invoke-HandbrakeConversion: Processing $Path for $Language audio streams" -Type Verbose
        
        # Get filtered audio streams using the centralized function
        $allStreams = Get-FilteredAudioStreams -Path $Path -Language $Language -Count 10

        Write-Message "Invoke-HandbrakeConversion: Files ($($allStreams.Count)): $($allStreams.Keys -join ', ')" -Type Verbose

        # Use centralized temp directory management
        Use-TempDirectory -ScriptBlock {
            param($TempDirectory)

            # Start progress tracking for file conversion
            $progress = Start-ProgressActivity -Activity 'HandBrake Conversion' -Status 'Starting conversion...' -TotalItems $allStreams.Count
            $currentFile = 0

            # Encode original MKV files to downres video with audio streams encoded appropriately
            foreach ($streamFile in $allStreams.Values) {
                $currentFile++
                $inputFile = Get-Path -Path $streamFile.File -PathType Absolute
                $fileName = [System.IO.Path]::GetFileName($inputFile)
                $streams = $streamFile.Streams
                
                Write-Message "Invoke-HandbrakeConversion: Converting $fileName to $Destination" -Type Verbose
                
                # Update progress
                # Update progress
                $progress.Update(@{
                        CurrentItem = $currentFile
                        Status      = "Converting: $fileName (Streams count $($streams.Count))"
                    })
                
                # Get HandBrake options using centralized function
                Write-Message "Converting file: $inputFile; Streams count: $($streams.Count)" -Type Verbose
                $handbrakeOptions = Get-HandbrakeOptions -AudioStreams $streams -Encoder 'mpeg2' -Quality '31' -EncoderPreset 'ultrafast'
                
                Write-Message "Invoke-HandbrakeConversion: Copying $inputFile to $TempDirectory" -Type Verbose
                Copy-Item -Path $inputFile -Destination $TempDirectory | Out-Null

                Write-Message "Invoke-HandbrakeConversion: Converting $inputFile from $TempDirectory to $Destination" -Type Verbose
                Convert-VideoFiles -Files $inputFile -Destination $Destination -Format mkv -HandbrakeOptions $handbrakeOptions -Force

                Write-Message 'Invoke-HandbrakeConversion: Updating audio tracks to preserve title' -Type Verbose
                $titles = $streams | Select-Object -ExpandProperty Title
                
                $handbrakeFile = Get-Path -Path $Destination, $fileName -PathType Absolute -ValidatePath File
                Rename-FileAudioStream -File $handbrakeFile -Titles $titles -TempDirectory $TempDirectory

                Write-Message "Invoke-HandbrakeConversion: Converted $($inputFile)" -Type Verbose
            }

            # Complete progress
            $progress.Stop(@{ Status = 'Conversion completed successfully' })
        }
    }

    end {
        Write-Message 'HandBrake conversion process completed' -Type Verbose
    }
} 
