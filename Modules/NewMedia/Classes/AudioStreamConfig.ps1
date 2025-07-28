<#
    .SYNOPSIS
    AudioStreamConfig - Configuration class for audio stream processing during video conversion.

    .DESCRIPTION
    AudioStreamConfig represents a single audio stream configuration for video conversion operations.
    This class defines how an input audio stream should be processed, whether by encoding to a new
    codec or copying the original stream as-is.

    The class supports two modes:
    - Encoding: Convert the audio stream to a new codec with specified bitrate and channels
    - Copying: Preserve the original audio stream without re-encoding

    Properties:
    - InputStreamIndex: The index of the input audio stream to process
    - Codec: The target audio codec for encoding (e.g., 'aac', 'mp3', 'ac3')
    - Bitrate: The bitrate for the encoded stream (e.g., '384k', '192k')
    - Channels: The number of audio channels for the encoded stream
    - Title: The metadata title for the audio stream
    - Copy: Boolean indicating whether to copy the stream as-is

    Constructors:
    - AudioStreamConfig(inputStreamIndex, codec, bitrate, channels, title): For encoding
    - AudioStreamConfig(inputStreamIndex, title): For copying

    Methods:
    - ToString(): Returns a human-readable description of the configuration

    .EXAMPLE
    # Create an encoding configuration
    $encodeConfig = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
    Write-Host $encodeConfig.ToString()
    # Output: Stream 1 -> aac 384k 6ch (Surround 5.1)

    .EXAMPLE
    # Create a copy configuration
    $copyConfig = [AudioStreamConfig]::new(0, 'DTS-HD')
    Write-Host $copyConfig.ToString()
    # Output: Stream 0 -> Copy (DTS-HD)

    .EXAMPLE
    # Using with Convert-VideoFile
    $audioConfigs = @(
        [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1'),
        [AudioStreamConfig]::new(0, 'DTS-HD')
    )
    Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4" -AudioStreams $audioConfigs

    .NOTES
    This class is designed to work with the Convert-VideoFile function and provides a flexible
    way to configure audio stream processing. The InputStreamIndex corresponds to the audio
    stream index in the input file (0-based).

    Common audio codecs:
    - 'aac': Advanced Audio Coding (widely compatible)
    - 'mp3': MPEG Audio Layer III (universal compatibility)
    - 'ac3': Dolby Digital (good for surround sound)
    - 'copy': Preserve original codec (no re-encoding)

    Common bitrates:
    - '80k': Best for single-channel
    - '160k': Best for two-channel
    - '384k': Surround 5.1
    - '512k': Surround 7.1

    Channel configurations:
    - 1: Mono
    - 2: Stereo
    - 6: 5.1 Surround
    - 8: 7.1 Surround
#>
class AudioStreamConfig {
    <#
    .SYNOPSIS
        The index of the input audio stream to process (0-based).
    .DESCRIPTION
        This property specifies which audio stream from the input file should be processed.
        Audio streams are indexed starting from 0, so the first audio stream is 0,
        the second is 1, and so on.
    #>
    [int]$InputStreamIndex

    <#
    .SYNOPSIS
        The audio codec to use for encoding.
    .DESCRIPTION
        Specifies the target codec for audio encoding. Common values include:
        - 'aac': Advanced Audio Coding (recommended for MP4)
        - 'mp3': MPEG Audio Layer III (universal compatibility)
        - 'ac3': Dolby Digital (good for surround sound)
        - 'copy': Preserve original codec (when Copy = true)
    #>
    [string]$Codec

    <#
    .SYNOPSIS
        The bitrate for the encoded audio stream.
    .DESCRIPTION
        Specifies the target bitrate for audio encoding. Common values:
        - '128k': Low quality, small file size
        - '192k': Medium quality, balanced
        - '256k': Good quality, reasonable size
        - '384k': High quality, larger file size
        - '512k': Very high quality, large file size
    #>
    [string]$Bitrate

    <#
    .SYNOPSIS
        The number of audio channels for the encoded stream.
    .DESCRIPTION
        Specifies the number of audio channels for the encoded stream:
        - 1: Mono
        - 2: Stereo
        - 6: 5.1 Surround
        - 8: 7.1 Surround
    #>
    [int]$Channels

    <#
    .SYNOPSIS
        The metadata title for the audio stream.
    .DESCRIPTION
        This title will be embedded in the output file's metadata and can be
        used by media players to display the audio track name.
    #>
    [string]$Title

    <#
    .SYNOPSIS
        Whether to copy the audio stream as-is without re-encoding.
    .DESCRIPTION
        When true, the audio stream will be copied without re-encoding, preserving
        the original codec and quality. When false, the stream will be encoded
        using the specified Codec, Bitrate, and Channels.
    #>
    [bool]$Copy

    <#
    .SYNOPSIS
        Constructor for creating an encoding audio stream configuration.
    .DESCRIPTION
        Creates a new AudioStreamConfig for encoding an audio stream to a new codec.
        This constructor is used when you want to re-encode the audio stream with
        specific codec, bitrate, and channel settings.
    .PARAMETER inputStreamIndex
        The index of the input audio stream to process (0-based).
    .PARAMETER codec
        The target audio codec for encoding (e.g., 'aac', 'mp3', 'ac3').
    .PARAMETER bitrate
        The bitrate for the encoded stream (e.g., '384k', '192k').
    .PARAMETER channels
        The number of audio channels for the encoded stream.
    .PARAMETER title
        The metadata title for the audio stream.
    .EXAMPLE
        $config = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
        # Creates configuration to encode stream 1 as AAC 6-channel 384kbps
    #>
    AudioStreamConfig([int]$inputStreamIndex, [string]$codec, [string]$bitrate, [int]$channels, [string]$title) {
        $this.InputStreamIndex = $inputStreamIndex
        $this.Codec = $codec
        $this.Bitrate = $bitrate
        $this.Channels = $channels
        $this.Title = $title
        $this.Copy = $false
    }

    <#
    .SYNOPSIS
        Constructor for creating a copy audio stream configuration.
    .DESCRIPTION
        Creates a new AudioStreamConfig for copying an audio stream as-is without re-encoding.
        This constructor is used when you want to preserve the original audio codec and quality.
    .PARAMETER inputStreamIndex
        The index of the input audio stream to process (0-based).
    .PARAMETER title
        The metadata title for the audio stream.
    .EXAMPLE
        $config = [AudioStreamConfig]::new(0, 'DTS-HD')
        # Creates configuration to copy stream 0 as-is
    #>
    AudioStreamConfig([int]$inputStreamIndex, [string]$title) {
        $this.InputStreamIndex = $inputStreamIndex
        $this.Codec = 'copy'
        $this.Bitrate = $null
        $this.Channels = $null
        $this.Title = $title
        $this.Copy = $true
    }

    <#
    .SYNOPSIS
        Returns a human-readable description of the audio stream configuration.
    .DESCRIPTION
        Converts the AudioStreamConfig to a string representation that clearly shows
        the stream mapping and processing details. The format depends on whether the
        configuration is for encoding or copying.
    .RETURNVALUE
        A string describing the audio stream configuration.
    .EXAMPLE
        $config = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
        Write-Host $config.ToString()
        # Output: Stream 1 -> aac 384k 6ch (Surround 5.1)
    .EXAMPLE
        $config = [AudioStreamConfig]::new(0, 'DTS-HD')
        Write-Host $config.ToString()
        # Output: Stream 0 -> Copy (DTS-HD)
    #>
    [string]ToString() {
        if ($this.Copy) {
            return "Stream $($this.InputStreamIndex) -> Copy ($($this.Title))"
        } else {
            return "Stream $($this.InputStreamIndex) -> $($this.Codec) $($this.Bitrate) $($this.Channels)ch ($($this.Title))"
        }
    }

    <#
    .SYNOPSIS
        Returns FFmpeg arguments for the audio stream configuration.
    .DESCRIPTION
        Generates the appropriate FFmpeg arguments based on the audio stream configuration.
        For encoding configurations, this includes codec, bitrate, and channel settings.
        For copy configurations, this includes the copy codec setting.
        The method also includes metadata arguments for the audio stream title.
    .PARAMETER outputStreamIndex
        The index of the output audio stream (0-based).
    .RETURNVALUE
        An array of FFmpeg arguments for audio stream processing.
    .EXAMPLE
        $config = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
        $args = $config.ToFfmpegArgs(0)
        # Returns: @('-map', '0:a:1', '-c:a:0', 'aac', '-b:a:0', '384k', '-ac:a:0', '6', '-metadata:s:a:0', 'title=Surround 5.1')
    .EXAMPLE
        $config = [AudioStreamConfig]::new(0, 'DTS-HD')
        $args = $config.ToFfmpegArgs(0)
        # Returns: @('-map', '0:a:0', '-c:a:0', 'copy', '-metadata:s:a:0', 'title=DTS-HD')
    #>
    [object[]]ToFfmpegArgs([int]$outputStreamIndex) {
        $args = @('-map', "0:a:$($this.InputStreamIndex)")

        if ($this.Copy) {
            $args += "-c:a:$outputStreamIndex", 'copy'
        } else {
            $args += "-c:a:$outputStreamIndex", $this.Codec
            if ($this.Bitrate) {
                $args += "-b:a:$outputStreamIndex", $this.Bitrate
            }
            if ($this.Channels) {
                $args += "-ac:a:$outputStreamIndex", $this.Channels.ToString()
            }
        }

        # Add metadata
        $args += "-metadata:s:a:$outputStreamIndex", "title=`"$($this.Title)`""

        return $args
    }
}
