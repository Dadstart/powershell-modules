function Export-MediaStream {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath,
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,
        [Parameter(Mandatory, Position = 2)]
        [ValidateSet('Video', 'Audio', 'Subtitle', 'Data', 'All')]
        [string]$Type,
        [Parameter(Mandatory, Position = 3)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Index,
        [Parameter()]
        [switch]$Force
    )
    process {
        Write-Message 'Export-MediaStream: Starting stream extraction' -Type Processing
        Write-Message "InputPath: $InputPath; OutputPath: $OutputPath; Type: $Type; Index: $Index" -Type Debug

        # Validate and resolve input path
        $inputFile = Get-Path -Path $InputPath -ValidatePath File -PathType Absolute
        Write-Message "Input file resolved to: $($inputFile)" -Type Debug

        # Validate and resolve output path
        $outputFile = Get-Path -Path $OutputPath -PathType Absolute
        Write-Message "Output file resolved to: $($outputFile)" -Type Debug

        # Check if output file exists and handle Force parameter
        if (Test-Path $outputFile) {
            if ($Force) {
                Write-Message "Output file exists and Force specified. Will overwrite: $($outputFile)" -Type Warning
            }
            else {
                Write-Message "Output file already exists: $($outputFile). Use -Force to overwrite." -Type Error
                throw "Output file already exists: $($outputFile). Use -Force to overwrite."
            }
        }

        # Ensure output directory exists
        $outputDirectory = Get-Path -Path $outputFile -PathType Parent -Create Directory
        Write-Message "Output directory ensured: $($outputDirectory)" -Type Debug

        # Build FFmpeg arguments for stream extraction
        $ffmpegArgs = New-Object System.Collections.Generic.List[string]
        $ffmpegArgs.Add('-i')
        $ffmpegArgs.Add($inputFile)

        # Add stream mapping based on type and index
        if ($Type -eq 'All') {
            # Extract by absolute stream index
            $ffmpegArgs.Add('-map')
            $ffmpegArgs.Add("0:$Index")
        }
        else {
            # Extract by stream type and index
            $streamTypeMap = @{
                'Video' = 'v'
                'Audio' = 'a'
                'Subtitle' = 's'
                'Data' = 'd'
            }
            $streamType = $streamTypeMap[$Type]
            $ffmpegArgs.Add('-map')
            $ffmpegArgs.Add("0:$streamType`:$Index")
        }

        # Add output file
        $ffmpegArgs.Add('-c')
        $ffmpegArgs.Add('copy')  # Copy stream without re-encoding
        $ffmpegArgs.Add($outputFile)

        $ffmpegArgsArray = $ffmpegArgs.ToArray()
        Write-Message "FFmpeg arguments: $($ffmpegArgsArray -join ' ')" -Type Debug

        # Execute FFmpeg
        $inputFileName = Get-Path -Path $inputFile -PathType Leaf
        $outputFileName = Get-Path -Path $outputFile -PathType Leaf
        if ($PSCmdlet.ShouldProcess("Extract stream from '$inputFileName' to '$outputFileName'", 'Extract stream')) {
            Write-Message 'Executing FFmpeg to extract stream...' -Type Processing
            Write-Message "FFmpeg arguments: $($ffmpegArgsArray -join ' ')" -Type Debug
            $result = Invoke-FFMpeg $ffmpegArgsArray
            Write-Message "FFmpeg result: $($result | ConvertTo-Json -Compress)" -Type Verbose

            if ($result.ExitCode -eq 0) {
                Write-Message "Successfully extracted stream to: '$outputFileName'" -Type Success
            }
            else {
                Write-Message "Failed to extract stream. FFmpeg exit code: $($result.ExitCode)" -Type Error
                Write-Message "FFmpeg error output: $($result.Error)" -Type Error
                throw "Failed to extract stream. FFmpeg exit code: $($result.ExitCode)"
            }
        }
        else {
            Write-Message "WhatIf: Would extract stream from '$inputFileName' to '$outputFileName'" -Type Info
        }
    }
}
