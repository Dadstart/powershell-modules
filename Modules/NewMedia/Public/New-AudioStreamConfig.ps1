function New-AudioStreamConfig {
    [CmdletBinding(DefaultParameterSetName = 'Encode')]
    <#
    .SYNOPSIS
        Creates an audio stream configuration for video conversion.
    .DESCRIPTION
        New-AudioStreamConfig creates an AudioStreamConfig object that defines how an audio stream
        should be processed during video conversion. It supports both encoding (AAC, MP3, etc.) and
        copying (preserving original codec).
    .PARAMETER InputStreamIndex
        The index of the input audio stream to process.
    .PARAMETER Codec
        The audio codec to use for encoding (e.g., 'aac', 'mp3', 'ac3').
    .PARAMETER Bitrate
        The bitrate for the encoded audio stream (e.g., '384k', '192k').
    .PARAMETER Channels
        The number of audio channels for the encoded stream.
    .PARAMETER Title
        The title metadata for the audio stream.
    .PARAMETER Copy
        When specified, copies the audio stream as-is without re-encoding.
    .EXAMPLE
        $config = New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'
        Creates a configuration to encode stream 1 as AAC 6-channel 384kbps.
    .EXAMPLE
        $config = New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy
        Creates a configuration to copy stream 0 as-is.
    .OUTPUTS
        [AudioStreamConfig] An audio stream configuration object.
    #>
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$InputStreamIndex,
        
        [Parameter(ParameterSetName = 'Encode', Mandatory = $true)]
        [string]$Codec,
        
        [Parameter(ParameterSetName = 'Encode')]
        [string]$Bitrate = '384k',
        
        [Parameter(ParameterSetName = 'Encode')]
        [int]$Channels = 6,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(ParameterSetName = 'Copy', Mandatory = $true)]
        [switch]$Copy
    )
    
    if ($Copy) {
        return [AudioStreamConfig]::new($InputStreamIndex, $Title)
    } else {
        return [AudioStreamConfig]::new($InputStreamIndex, $Codec, $Bitrate, $Channels, $Title)
    }
} 