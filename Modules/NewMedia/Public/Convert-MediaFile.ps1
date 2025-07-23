<#
.SYNOPSIS
Convert-MediaFile - Convert a media file to a new format

.DESCRIPTION
Convert-MediaFile is a function that converts a media file to a new format.

.PARAMETER InputFile
The path to the input file.

.PARAMETER OutputFile
The path to the output file.

.PARAMETER VideoSettings
The video settings to use for the conversion.

.PARAMETER AudioMappings
The audio mappings to use for the conversion.
#>
function Convert-MediaFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]] $InputFiles,
        [Parameter(Mandatory)][string] $OutputFile,
        [Parameter(Mandatory)][VideoEncodingSettings] $VideoSettings,
        [Parameter(Mandatory)][AudioTrackMapping[]] $AudioMappings
    )
    process {
        Test-FFMpegInstalled -Throw
        # Build video+audio
        $ff = New-Object System.Collections.Generic.List[string]
        $ff.Add('-y')
        foreach ($inputFile in $InputFiles) {
            $ff.Add('-i')
            $ff.Add("`"$inputFile`"")
        }
        $ff.AddRange($VideoSettings.ToFfMpegArgs())

        foreach ($am in $AudioMappings) {
            $ff.AddRange($am.ToFfmpegArgs())
        }
        $ff.Add('-sn')
        $ff.Add("`"$OutputFile`"")
        Write-Host "FFMPEG: $($ff.ToArray() -join ' ')" -ForegroundColor Green
        $result = Invoke-FFMpeg -Arguments $ff.ToArray()
        if ($result.ExitCode -ne 0) {
            Write-Error "Encode failed (ExitCode: $($result.ExitCode)): $($result.Error)"
            throw "Encode failed (ExitCode: $($result.ExitCode)): $($result.Error)"
        }
    }
}
