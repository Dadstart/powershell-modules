function New-AudioTrackMapping {
    <#
    .SYNOPSIS
        Creates a new AudioTrackMapping object for audio stream processing and conversion.
    
    .DESCRIPTION
        New-AudioTrackMapping creates an AudioTrackMapping object that defines how an audio stream
        should be processed during video encoding operations. This mapping specifies the source
        audio stream details and how it should be converted or copied to the destination output.
        
        The mapping can either copy the original audio stream without re-encoding (when CopyOriginal
        is true) or transcode it to a different codec with specified bitrate and channel configuration.
    
    .PARAMETER SourceStream
        The zero-based index of the source audio stream in the input file.

    .PARAMETER SourceIndex
        The zero-based index of the source audio stream in the input file.
    
    .PARAMETER DestinationIndex
        The zero-based index where this audio stream should appear in the output file.
    
    .PARAMETER DestinationCodec
        The target codec for the audio stream. Valid values include:
        'aac', 'ac3', 'eac3', 'mp3', 'vorbis', 'opus', 'flac', 'alac'
        Required when transcoding (CopyOriginal not specified).
    
    .PARAMETER DestinationBitrate
        The target bitrate in kilobits per second (kbps) for the audio stream.
        Will be automatically calculated based on DestinationChannels if not specified..

    .PARAMETER DestinationChannels
        The number of audio channels in the output (e.g., 1 for mono, 2 for stereo, 6 for 5.1).
        Required when transcoding (CopyOriginal not specified).
    
    .PARAMETER CopyOriginal
        When specified, the original audio stream is copied without re-encoding.
        Cannot be used with destinationCodec, destinationBitrate, or destinationChannels.
    
    .EXAMPLE
        $mapping = New-AudioTrackMapping
            -SourceIndex 0 -DestinationIndex 0
            -DestinationCodec 'aac' -DestinationBitrate 192 -DestinationChannels 2
        Creates a mapping to transcode the first audio stream to AAC at 192kbps stereo.
    
    .EXAMPLE
        $mapping = New-AudioTrackMapping
            -SourceIndex 1 -DestinationIndex 1
            -DestinationCodec 'aac' -DestinationBitrate 128 -DestinationChannels 1
        Creates a mapping to transcode the second audio stream to AAC mono at 128kbps.
    
    .EXAMPLE
        $mapping = New-AudioTrackMapping
            -SourceIndex 0 -DestinationIndex 0
            -copyOriginal
        Creates a mapping to copy the first audio stream without re-encoding.
    
    .OUTPUTS
        AudioTrackMapping
        Returns an AudioTrackMapping object that can be used with video encoding operations.
    
    .LINK
        AudioTrackMapping
    #>
    [CmdletBinding(DefaultParameterSetName = 'Transcode')]
    param(
        [Parameter(ParameterSetName = 'Copy')]
        [Parameter(ParameterSetName = 'Transcode')]
        [int]    $SourceStream = 0,
        [Parameter(Mandatory, ParameterSetName = 'Copy')]
        [Parameter(Mandatory, ParameterSetName = 'Transcode')]
        [int]    $SourceIndex,
        [Parameter(Mandatory, ParameterSetName = 'Copy')]
        [Parameter(Mandatory, ParameterSetName = 'Transcode')]
        [int]    $DestinationIndex,
        [Parameter(Mandatory, ParameterSetName = 'Transcode')]
        [ValidateSet('aac', 'ac3', 'eac3', 'mp3', 'vorbis', 'opus', 'flac', 'alac')]
        [string] $DestinationCodec,
        [Parameter(ParameterSetName = 'Transcode')]
        [int]    $DestinationBitrate,
        [Parameter(Mandatory, ParameterSetName = 'Transcode')]
        [int]    $DestinationChannels,
        [Parameter(Mandatory, ParameterSetName = 'Copy')]
        [switch] $CopyOriginal,
        [Parameter(Mandatory, ParameterSetName = 'Copy')]
        [Parameter(Mandatory, ParameterSetName = 'Transcode')]
        [string] $Title
    )
    process {
        if ($CopyOriginal) {
            return [AudioTrackMapping]::new($SourceStream, $SourceIndex, $DestinationIndex, $null, 0, 0, $true, $Title)
        }
        else {
            return [AudioTrackMapping]::new($SourceStream, $SourceIndex, $DestinationIndex, $DestinationCodec, $DestinationBitrate, $DestinationChannels, $false, $Title)
        }
    }
}