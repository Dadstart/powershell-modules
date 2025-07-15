function Add-MediaStream {
    <#
    .SYNOPSIS
        Adds additional media streams to an existing video file.

    .DESCRIPTION
        This function uses FFmpeg to add additional audio, video, or subtitle streams to an existing video file.
        Each stream object must contain File, Language, Title, and Type properties.
        The function preserves the original video stream and adds the specified streams with proper metadata.

    .PARAMETER Streams
        An array of stream objects, each containing:
        - File: Path to the media file containing the stream
        - Language: Language code (e.g., 'eng', 'spa', 'fra')
        - Title: Display title for the stream
        - Type: Stream type ('Audio', 'Video', 'Subtitle')

    .PARAMETER InputPath
        Path to the source video file that will receive the additional streams.

    .PARAMETER OutputPath
        Path where the output file with added streams will be saved.

    .EXAMPLE
        $streams = @(
            [PSCustomObject]@{
                File = 'audio-eng.m4a'
                Language = 'eng'
                Title = 'English Stereo'
                Type = 'Audio'
            },
            [PSCustomObject]@{
                File = 'audio-spa.m4a'
                Language = 'spa'
                Title = 'Spanish Stereo'
                Type = 'Audio'
            }
        )
        
        Add-MediaStream -Streams $streams -InputPath 'movie.mp4' -OutputPath 'movie-multiaudio.mp4'
        
        # Adds English and Spanish audio tracks to movie.mp4

    .EXAMPLE
        $subtitleStream = [PSCustomObject]@{
            File = 'subtitles-eng.srt'
            Language = 'eng'
            Title = 'English Subtitles'
            Type = 'Subtitle'
        }
        
        Add-MediaStream -Streams $subtitleStream -InputPath 'movie.mp4' -OutputPath 'movie-with-subs.mp4'
        
        # Adds English subtitle track to movie.mp4

    .EXAMPLE
        $streams = @(
            [PSCustomObject]@{
                File = 'commentary.m4a'
                Language = 'eng'
                Title = 'Director Commentary'
                Type = 'Audio'
            }
        )
        
        'movie.mp4' | Add-MediaStream -Streams $streams -OutputPath 'movie-commentary.mp4'
        
        # Uses pipeline to add commentary track to movie.mp4

    .OUTPUTS
        None. Creates a new video file with the specified streams added.

    .NOTES
        - Requires FFmpeg to be installed and available in the system PATH
        - The original video stream is preserved and copied without re-encoding
        - Audio streams are copied without re-encoding to preserve quality
        - The -shortest flag ensures the output duration matches the shortest input stream
        - Stream metadata (language and title) is properly set for media players
        - Input files must exist and be valid media files
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$Streams,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    Write-Verbose "Adding $($Streams.Count) streams to $OutputPath"

    # Build input arguments
    <# Final arguments will look something like this:
        ffmpeg
            -i "$InputPath"
            -i "$($Streams[0].File)"
            -i "$($Streams[1].File)"
            -map 0:v:0
            -map 1:a:0
            -map 2:a:0
            [... for each stream]
            -c copy
            -metadata:s:a:0 title="$($Streams[0].Title)" -metadata:s:a:0 language=$($Streams[0].Language)
            -metadata:s:a:1 title="$($Streams[1].Title)" -metadata:s:a:1 language=$($Streams[1].Language)
            [... for each stream]
            "$OutputPath"
      #>

    $inputs = [System.Collections.Generic.List[string]]::new()
    $maps = [System.Collections.Generic.List[string]]::new()
    $metadata = [System.Collections.Generic.List[string]]::new()
    
    # Add main video file as input #0
    # -i specifies an input file
    $inputs.Add('-i')
    $quotedInputPath = '"' + $InputPath + '"'
    $inputs.Add($quotedInputPath)
    
    # Map the video stream from input #0
    # -map 0:v maps the video stream from the first input file (index 0)
    $maps.Add('-map')
    $maps.Add('0:v:0')

    for ($i = 0; $i -lt $Streams.Count; $i++) {
        $stream = $Streams[$i]
        Write-Verbose "Adding $($stream.Type) stream #$i to $OutputPath. Title: $($stream.Title) Language: $($stream.Language)"

        # Add additional stream file as input #(i+1)
        # Each additional file becomes input #1, #2, #3, etc.
        $inputs.Add('-i')
        $quotedStreamFile = '"' + $stream.File + '"'
        $inputs.Add($quotedStreamFile)

        # Convert stream type to FFmpeg short form
        # FFmpeg uses single letters: 'a' for audio, 'v' for video, 's' for subtitle
        $ffmpegType = switch ($stream.Type) {
            'Audio' { 'a' }
            'Video' { 'v' }
            'Subtitle' { 's' }
            default { throw "Invalid stream type: $($stream.Type)" }
        }
        
        # Map the stream from input #(i+1)
        # -map 1:a:0 maps the first audio stream from the second input file
        # -map 2:a:0 maps the second audio stream from the third input file
        # etc.
        $maps.Add('-map')
        $maps.Add("$($i + 1):$ffmpegType`:0")

        # Add metadata for this stream
        # -metadata:s:a:0 key=value sets metadata for the first audio stream in the output
        # -metadata:s:a:1 key=value sets metadata for the second audio stream in the output
        $metadata.Add("-metadata:s:$ffmpegType`:$i")
        $metadata.Add("language=$($stream.Language)")
        $metadata.Add("-metadata:s:$ffmpegType`:$i") 
        $metadata.Add("title=`"$($stream.Title)`"")
    }

    # Assemble the final ffmpeg command
    $args = [System.Collections.Generic.List[string]]::new()
    
    # Add all input files (-i arguments)
    Write-Verbose "Inputs: $($inputs -join ' ')"
    $args.AddRange($inputs)
    
    # Add all stream mappings (-map arguments)
    Write-Verbose "Maps: $($maps -join ' ')"
    $args.AddRange($maps)
    
    # Copy all streams without re-encoding to preserve quality
    # -c copy is equivalent to -c:v copy -c:a copy -c:s copy
    $args.Add('-c')
    $args.Add('copy')
    
    # Force overwrite output file without prompting
    $args.Add('-y')
    
    # Add all metadata tags
    Write-Verbose "Metadata: $($metadata -join ' ')"
    $args.AddRange($metadata)
    
    # Add the output file path
    $quotedOutputPath = '"' + $OutputPath + '"'
    Write-Verbose "OutputPath: $quotedOutputPath"
    $args.Add($quotedOutputPath)

    $argsArray = $args.ToArray()
    Write-Verbose "FFmpeg command: ffmpeg $($argsArray -join ' ')"
    Invoke-FFMpeg -Arguments $argsArray | Out-Null
}
