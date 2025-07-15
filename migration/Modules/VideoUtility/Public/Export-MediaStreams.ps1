function Export-MediaStreams {
    <#
    .SYNOPSIS
        Exports all streams of a specific type from a media file.

    .DESCRIPTION
        This function extracts all streams of a specified type (Audio, Video, or Subtitle) from a media file
        and saves them as separate files in the specified output directory. Each stream is saved with
        a filename that includes the original filename, stream index, and codec name.

        The function automatically generates output filenames using the pattern:
        {original_filename}.{stream_index}.{codec_name}

        For example, if extracting audio streams from "movie.mkv", the output files might be:
        - movie.0.aac (first audio stream)
        - movie.1.ac3 (second audio stream)

    .PARAMETER InputFile
        Path to the input media file. This parameter accepts pipeline input.

    .PARAMETER OutputDirectory
        Directory where the extracted stream files will be saved. The directory will be created
        if it doesn't exist.

    .PARAMETER Type
        Type of streams to extract. Must be one of: Audio, Video, or Subtitle.

    .PARAMETER Force
        Overwrites existing output files without prompting. By default, the function skips
        files that already exist.

    .EXAMPLE
        Export-MediaStreams -InputFile 'movie.mkv' -OutputDirectory 'C:\extracted' -Type Audio
        Extracts all audio streams from 'movie.mkv' and saves them to 'C:\extracted' directory.

    .EXAMPLE
        Export-MediaStreams -InputFile 'video.mp4' -OutputDirectory '.\audio' -Type Audio -Force
        Extracts all audio streams from 'video.mp4', overwriting any existing files in '.\audio' directory.

    .EXAMPLE
        Export-MediaStreams -InputFile 'movie.mkv' -OutputDirectory '.\subtitles' -Type Subtitle
        Extracts all subtitle streams from 'movie.mkv' and saves them to '.\subtitles' directory.

    .EXAMPLE
        Get-ChildItem -Filter "*.mp4" | Export-MediaStreams -OutputDirectory ".\extracted" -Type Video
        Extracts all video streams from all MP4 files in the current directory and saves them to ".\extracted".

    .EXAMPLE
        Export-MediaStreams -InputFile 'movie.mkv' -OutputDirectory '.\audio' -Type Audio -Verbose
        Extracts all audio streams with detailed verbose output showing the extraction process.

    .OUTPUTS
        None. Creates files in the specified OutputDirectory.

    .NOTES
        This function requires ffmpeg to be installed and available in the system PATH.
        
        The function uses Get-MediaStreams to enumerate streams and Export-MediaStream to extract
        individual streams. Each extracted stream maintains its original codec and quality.
        
        Stream indices are zero-based, so the first stream of a type has index 0.
        
        If the OutputDirectory doesn't exist, it will be created automatically.
        
        Use -Verbose to see detailed information about the extraction process.

    .LINK
        Export-MediaStream
        Get-MediaStreams
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputFile,
        [Parameter(Mandatory)]
        [string]$OutputDirectory,
        [Parameter(Mandatory)]
        [ValidateSet('Audio','Subtitle','Video')]
        [string]$Type,
        [Parameter()]
        [switch]$Force
    )
    begin {
        @(
            'Export-MediaStream',
            'Get-MediaStreams'
        ) | Set-PreferenceInheritance
    }
    process {
        # Resolve the input file path to absolute path
        $inputPath = Resolve-Path $InputFile
        Write-Verbose "InputPath: $($inputPath.Path)"
        
        # Get all streams of the specified type from the input file
        Get-MediaStreams -Path $inputPath.Path -Type $Type | ForEach-Object {
            # Generate file extension based on stream index and codec name
            # Note: Using Index directly because MediaStream objects use 0-based indices
            # which is what Export-MediaStream expects
            $extension = ".$($_.Index).$($_.CodecName)"
            Write-Verbose "Extension: $extension"
            
            # Build the output path by combining output directory, original filename, and extension
            $outputPath = (Resolve-Path $OutputDirectory).Path
            $outputPath =  ([System.IO.Path]::Combine($outputPath, '\', [System.IO.Path]::GetFileNameWithoutExtension($inputFile), $extension -join ''))
            Write-Verbose "OutputPath: $outputPath"

            # Check if output file already exists and handle Force parameter
            if (Test-Path $outputPath -and -not $Force) {
                Write-Host "$Type stream already exists: $outputPath"
                continue
            }

            # Extract the current stream using Export-MediaStream
            Write-Host "Exporting $Type stream #$($_.Index) to $outputPath"
            Export-MediaStream -InputPath ($inputPath.Path) -OutputPath $outputPath -Type $Type -Index $_.Index
        }
    }
}