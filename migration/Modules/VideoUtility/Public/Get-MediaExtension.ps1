function Get-MediaExtension {
    <#
    .SYNOPSIS
        Maps media codec names to appropriate file extensions based on codec type.

    .DESCRIPTION
        This function takes a codec type and codec name and returns the appropriate file extension
        for that codec. It handles common codecs for audio, subtitle, and video streams.

    .PARAMETER CodecType
        The type of codec: 'Audio', 'Subtitle', or 'Video'.

    .PARAMETER CodecName
        The codec name to map to an extension.

    .EXAMPLE
        Get-MediaExtension -CodecType Audio -CodecName 'aac'
        Returns: '.aac'

    .EXAMPLE
        Get-MediaExtension -CodecType Subtitle -CodecName 'subrip'
        Returns: '.srt'

    .EXAMPLE
        Get-MediaExtension -CodecType Video -CodecName 'h264'
        Returns: '.mp4'

    .EXAMPLE
        Get-MediaExtension -CodecType Audio -CodecName 'unknown'
        Returns: '.unknown'

    .OUTPUTS
        [string] - The file extension including the leading dot.

    .NOTES
        Common codec mappings by type:
        
        Audio:
        - aac -> .aac (Advanced Audio Coding)
        - ac3 -> .ac3 (Dolby Digital)
        - dts -> .dts (Digital Theater Systems)
        - mp3 -> .mp3 (MPEG Audio Layer III)
        - flac -> .flac (Free Lossless Audio Codec)
        - wav -> .wav (Waveform Audio File Format)
        
        Subtitle:
        - subrip -> .srt (SubRip text format)
        - hdmv_pgs_subtitle -> .sup (Blu-ray PGS subtitles)
        - dvd_subtitle -> .mkv (DVD subtitles)
        - ass -> .ass (Advanced SubStation Alpha)
        - webvtt -> .vtt (WebVTT)
        
        Video:
        - h264 -> .mp4 (H.264/AVC)
        - h265 -> .mp4 (H.265/HEVC)
        - vp9 -> .webm (VP9)
        - av1 -> .mp4 (AV1)
        - mpeg2video -> .mpg (MPEG-2)
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Audio', 'Subtitle', 'Video')]
        [string]$CodecType,

        [Parameter(Mandatory)]
        [string]$CodecName
    )

    # Define codec extension mappings for each type
    $codecExtensionMaps = @{
        'Audio' = @{
            'aac'               = '.aac'    # Advanced Audio Coding
            'ac3'               = '.ac3'    # Dolby Digital
            'dts'               = '.dts'    # Digital Theater Systems
            'mp3'               = '.mp3'    # MPEG Audio Layer III
            'flac'              = '.flac'   # Free Lossless Audio Codec
            'wav'               = '.wav'    # Waveform Audio File Format
            'ogg'               = '.ogg'    # Ogg Vorbis
            'opus'              = '.opus'   # Opus audio codec
            'pcm_s16le'         = '.wav'    # PCM 16-bit little-endian
            'pcm_s24le'         = '.wav'    # PCM 24-bit little-endian
            'pcm_s32le'         = '.wav'    # PCM 32-bit little-endian
            'pcm_s16be'         = '.wav'    # PCM 16-bit big-endian
            'pcm_s24be'         = '.wav'    # PCM 24-bit big-endian
            'pcm_s32be'         = '.wav'    # PCM 32-bit big-endian
            'eac3'              = '.eac3'   # Enhanced AC-3
            'dts-hd'            = '.dts'    # DTS-HD Master Audio
            'dts-hd ma'         = '.dts'    # DTS-HD Master Audio
            'dts-hd hra'        = '.dts'    # DTS-HD High Resolution Audio
            'dtsx'              = '.dts'    # DTS:X
            'truehd'            = '.thd'    # Dolby TrueHD
            'ac4'               = '.ac4'    # Dolby AC-4
            'atmos'             = '.thd'    # Dolby Atmos (usually in TrueHD container)
            'mlp'               = '.mlp'    # Meridian Lossless Packing
            'alac'              = '.m4a'    # Apple Lossless Audio Codec
            'amr'               = '.amr'    # Adaptive Multi-Rate
            'amr_wb'            = '.amr'    # Adaptive Multi-Rate Wideband
            'ra_144'            = '.ra'     # RealAudio 1
            'ra_288'            = '.ra'     # RealAudio 2
            'vorbis'            = '.ogg'    # Vorbis (usually in Ogg container)
            'mp2'               = '.mp2'    # MPEG Audio Layer II
            'mp4a'              = '.m4a'    # MPEG-4 Audio
            'mp4s'              = '.m4a'    # MPEG-4 Audio (alternative)
            'adpcm_ima_wav'     = '.wav'    # IMA ADPCM
            'adpcm_ms'          = '.wav'    # Microsoft ADPCM
            'gsm'               = '.gsm'    # GSM 6.10
            'gsm_ms'            = '.gsm'    # Microsoft GSM 6.10
            'qdm2'              = '.qdm'    # QDesign Music 2
            'qdmc'              = '.qdm'    # QDesign Music
            'qclp'              = '.qclp'   # QDesign Music (alternative)
            'nellymoser'        = '.nmf'    # Nellymoser Asao
            'speex'             = '.spx'    # Speex
            'wma'               = '.wma'    # Windows Media Audio
            'wma1'              = '.wma'    # Windows Media Audio 1
            'wma2'              = '.wma'    # Windows Media Audio 2
            'wma3'              = '.wma'    # Windows Media Audio 3
            'wmapro'            = '.wma'    # Windows Media Audio Professional
            'wmavoice'          = '.wma'    # Windows Media Audio Voice
            'wmav2'             = '.wma'    # Windows Media Audio 2 (alternative)
            'wmav3'             = '.wma'    # Windows Media Audio 3 (alternative)
            'atrac'             = '.at3'    # ATRAC
            'atrac3'            = '.at3'    # ATRAC3
            'atrac3p'           = '.at3'    # ATRAC3+
            'cook'              = '.cook'   # Cook
            'sipr'              = '.sipr'   # Sipro
            'ralf'              = '.ralf'   # RealAudio Lossless
            'iac'               = '.iac'    # IAC
            'ilbc'              = '.lbc'    # iLBC
            'g723_1'            = '.g723'   # G.723.1
            'g726'              = '.g726'   # G.726
            'g726le'            = '.g726'   # G.726 little-endian
            'g729'              = '.g729'   # G.729
            '8svx_exp'          = '.8svx'   # 8SVX exponential
            '8svx_fib'          = '.8svx'   # 8SVX fibonacci
            'bmv_audio'         = '.bmv'    # Discworld II BMV audio
        }
        
        'Subtitle' = @{
            'subrip'             = '.srt'    # SubRip text format
            'hdmv_pgs_subtitle'  = '.sup'    # Blu-ray PGS subtitles
            'dvd_subtitle'       = '.mkv'    # DVD subtitles stay in an mkv. Ffmpeg things '.sub' is a microdvd codec.
            'ass'                = '.ass'    # Advanced SubStation Alpha
            'ssa'                = '.ssa'    # SubStation Alpha
            'mov_text'           = '.txt'    # QuickTime text
            'webvtt'             = '.vtt'    # WebVTT
            'eia_608'            = '.txt'    # EIA-608 captions
            'eia_708'            = '.txt'    # EIA-708 captions
            'hdmv_text_subtitle' = '.txt'    # Blu-ray text subtitles
            'xsub'               = '.mkv'    # XSUB format stay in an mkv. Ffmpeg things '.sub' is a microdvd codec.
            'microdvd'           = '.sub'    # MicroDVD format
            'sami'               = '.smi'    # SAMI captions
            'realtext'           = '.rt'     # RealText
            'pjs'                = '.pjs'    # Phoenix Subtitle
            'mpl2'               = '.txt'    # MPL2 format
            'stl'                = '.stl'    # Spruce subtitle format
            'scc'                = '.scc'    # Scenarist Closed Captions
            'ttml'               = '.ttml'   # Timed Text Markup Language
            'dfxp'               = '.dfxp'   # Distribution Format Exchange Profile
            'srt'                = '.srt'    # SubRip (already an extension)
            'vtt'                = '.vtt'    # WebVTT (already an extension)
        }
        
        'Video' = @{
            'h264'               = '.mp4'    # H.264/AVC
            'h265'               = '.mp4'    # H.265/HEVC
            'hevc'               = '.mp4'    # H.265/HEVC (alternative name)
            'vp9'                = '.webm'   # VP9
            'av1'                = '.mp4'    # AV1
            'mpeg2video'         = '.mpg'    # MPEG-2
            'mpeg4'              = '.mp4'    # MPEG-4
            'msmpeg4v3'          = '.avi'    # Microsoft MPEG-4 v3
            'wmv1'               = '.wmv'    # Windows Media Video 1
            'wmv2'               = '.wmv'    # Windows Media Video 2
            'wmv3'               = '.wmv'    # Windows Media Video 3
            'vc1'                = '.wmv'    # VC-1
            'theora'             = '.ogv'    # Theora
            'dirac'              = '.drc'    # Dirac
            'mjpeg'              = '.avi'    # Motion JPEG
            'prores'             = '.mov'    # Apple ProRes
            'dnxhd'              = '.mov'    # Avid DNxHD
            'cinepak'            = '.avi'    # Cinepak
            'indeo'              = '.avi'    # Intel Indeo
            'qtrle'              = '.mov'    # QuickTime Animation/RLE
            'qtrpza'             = '.mov'    # QuickTime Planar RGB
            'qtsmc'              = '.mov'    # QuickTime SMC
        }
    }

    # Get the appropriate map for the codec type
    $codecMap = $codecExtensionMaps[$CodecType]
    
    if (-not $codecMap) {
        Write-Message "Unsupported codec type: $CodecType" -Type Warning
        return ".$CodecName"
    }

    # Get the extension from the map, or use the codec name as fallback
    $extension = $codecMap[$CodecName.ToLower()]
    
    if ($extension) {
        Write-Message "Mapped $CodecType codec '$CodecName' to extension '$extension'" -Type Verbose
        return $extension
    }
    else {
        Write-Message "No mapping found for $CodecType codec '$CodecName', using '.$CodecName' as extension" -Type Verbose
        return ".$CodecName"
    }
} 