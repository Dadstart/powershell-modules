<#
.SYNOPSIS
VideoEncodingSettings - A class that represents video encoding settings

.DESCRIPTION
VideoEncodingSettings is a class that represents video encoding settings.

.PARAMETER Codec
The codec to use. Supported values are 'x264'.

.PARAMETER CRF
The constant rate factor (CRF) value to use. Default is 21. Balances quality and file size (lower = better quality).

.PARAMETER Preset
The preset to use. Default is 'slow'.

.PARAMETER CodecProfile
The codec profile to use. Default is 'high'.

.PARAMETER Tune
The tune to use.

#>
class VideoEncodingSettings {
    [string] $Codec
    [double] $Bitrate
    [int]    $CRF
    [string] $Preset
    [string] $CodecProfile
    [string] $Tune
    [hashtable] $AdditionalArgs

    VideoEncodingSettings(
        [string] $codec,
        [double] $bitrate,
        [int]    $crf,
        [string] $preset,
        [string] $codecProfile,
        [string] $tune,
        [hashtable] $additionalArgs
    ) {
        $this.Codec = $codec
        $this.Bitrate = $bitrate
        $this.Preset = $preset
        $this.CRF = $crf
        $this.CodecProfile = $codecProfile
        $this.Tune = $tune
        $this.AdditionalArgs = $additionalArgs
    }


    [string] ToString() {
        if ($this.Bitrate) {
            return "$($this.Codec), Bitrate=$($this.Bitrate)k, Preset=$($this.Preset)"
        }
        else {

            return "$($this.Codec), CRF=$($this.CRF), Preset=$($this.Preset)"
        }
    }

    [ordered] ToFfmpegArgs([int] $pass, [string] $passLogFile) {
        if (($pass -lt 0) -or ($pass -gt 2)) {
            throw 'Phase must be 0, 1 or 2'
        }

        # Construct ffmpeg command
        $ffmpegArgs = [ordered]@{}
        if ($this.CRF -or ($pass -eq 2)) {
            $ffmpegArgs['-map'] = '0:v:0'
        }

        $libCodec = switch ($this.Codec) {
            'x264' {
                'libx264'
            }
            'x265' {
                'libx265'
            }
            default {
                $this.Codec
            }
        }

        $ffmpegArgs['-c:v'] = $libCodec
        $ffmpegArgs['-preset'] = $this.Preset
        if ($this.Bitrate) {
            $ffmpegArgs['-b:v'] = "$($this.Bitrate)k"
        }
        else {
            $ffmpegArgs['-crf'] = $this.CRF
            $ffmpegArgs['-pix_fmt'] = 'yuv420p'
        }

        if ($this.CRF -or ($pass -eq 2)) {
            $ffmpegArgs['-map_metadata'] = '0'
            $ffmpegArgs['-map_chapters'] = '0'
            $ffmpegArgs['-movflags'] = '+faststart'
        }

        switch ($libCodec) {
            'libx264' {
                switch ($pass) {
                    1 {
                        $ffmpegArgs['-pass'] = '1'
                        $ffmpegArgs['-passlogfile'] = $passLogFile
                    }
                    2 {
                        $ffmpegArgs['-pass'] = '2'
                        $ffmpegArgs['-passlogfile'] = $passLogFile
                    }
                }
            }
            'libx265' {
                switch ($pass) {
                    1 {
                        $ffmpegArgs['-x265-params'] += ':pass=1:stats=$passLogFile'
                    }
                    2 {
                        $ffmpegArgs['-x265-params'] += ':pass=2:stats=$passLogFile'
                    }
                }
            }
            default {
                throw "Unsupported codec: $libCodec"
            }
        }

        if ($this.AdditionalArgs) {
            foreach ($key in $this.AdditionalArgs.Keys) {
                $ffmpegArgs[$key] = $this.AdditionalArgs[$key]
            }
        }

        return $ffmpegArgs
    }
}
