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
.PARAMETER SubtitleMappings
The subtitle mappings to use for the conversion.
#>
function Convert-MediaFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $InputFile,
        [Parameter(Mandatory)][string] $OutputFile,
        [Parameter(Mandatory)][VideoEncodingSettings] $VideoSettings,
        [Parameter(Mandatory)][AudioTrackMapping[]] $AudioMappings,
        [SubtitleTrackMapping[]] $SubtitleMappings
    )
    process {
        Test-FFMpegInstalled -Throw
        # Build video+audio
        $ff = @('-y', '-i', $InputFile) + $VideoSettings.ToArgs()
        foreach ($am in $AudioMappings) {
            $ff += $am.ToMapArgs() 
        }
        $ff += '-sn', $OutputFile
        $r = Invoke-FFMpeg -Arguments $ff
        if ($r.Failure) {
            Write-Error 'Encode failed'; return 
        }
        Write-Host "Output: $OutputFile"
        # Extract subtitles
        foreach ($sm in $SubtitleMappings) {
            $args = $sm.ToExtractArgs($InputFile); $rs = Invoke-FFMpeg -Arguments $args
            if ($rs.Failure) {
                Write-Warning "Subtitle $($sm.SourceIndex) failed" 
            }
            else {
                Write-Host "Extracted $($sm.OutputPath)" 
            }
        }
    }
}
