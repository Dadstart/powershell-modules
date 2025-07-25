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
        [Parameter(Mandatory)][object] $VideoSettings,
        [Parameter(Mandatory)][object[]] $AudioMappings
    )
    begin {
        @('Write-Message', 'Invoke-FFMpeg', 'Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        Test-FFMpegInstalled -Throw

        $baseArgs = New-Object System.Collections.Generic.List[string]
        $baseArgs.Add('-y')
        foreach ($inputFile in $InputFiles) {
            $baseArgs.Add('-i')
            $baseArgs.Add("`"$inputFile`"")
        }

        # Audio
        $audioArgs = New-Object System.Collections.Generic.List[string]
        foreach ($am in $AudioMappings) {
            $audioArgs.AddRange($am.ToFfmpegArgs())
        }

        if ($VideoSettings.Bitrate) {
            $passLogFile = [System.IO.Path]::ChangeExtension($OutputFile, '.ffmpeg')
            # Pass 1
            $pass1Args = New-Object System.Collections.Generic.List[string]
            $pass1Args.AddRange($baseArgs)
            $pass1Args.AddRange($VideoSettings.ToFfMpegArgs(1))
            $pass1Args.Add('-an')
            $pass1Args.Add('-sn')

            $finalArgs = New-Object System.Collections.Generic.List[string]
            $finalArgs.Add('-pass')
            $finalArgs.Add('1')
            $finalArgs.Add('-passlogfile')
            $finalArgs.Add("`"$passLogFile`"")
            $pass1Args.Add('-f')
            $pass1Args.Add('null')
            $pass1Args.Add('NUL')
            Convert-MediaFileFromArgumentList -BaseArgs $pass1Args -FinalArgs $finalArgs -Description 'VBR Pass 1'

            $pass2Args = New-Object System.Collections.Generic.List[string]
            $pass2Args.AddRange($baseArgs)
            $pass2Args.AddRange($VideoSettings.ToFfMpegArgs(2))

            $finalArgs = New-Object System.Collections.Generic.List[string]
            $finalArgs.Add('-pass')
            $finalArgs.Add('2')
            $finalArgs.Add('-passlogfile')
            $finalArgs.Add("`"$passLogFile`"")
            $finalArgs.Add("`"$OutputFile`"")

            Convert-MediaFileFromArgumentList -BaseArgs $pass2Args -AudioArgs $audioArgs -FinalArgs $finalArgs -Description 'VBR Pass 2'
        }
        else {
            $finalArgs = New-Object System.Collections.Generic.List[string]
            $finalArgs.Add("`"$OutputFile`"")

            Convert-MediaFileFromArgumentList -BaseArgs $baseArgs -AudioArgs $audioArgs -FinalArgs $finalArgs -Description 'CRF'
        }
    }
}

function Convert-MediaFileFromArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[string]] $BaseArgs,
        [Parameter()]
        [System.Collections.Generic.List[string]] $AudioArgs,
        [Parameter()]
        [System.Collections.Generic.List[string]] $FinalArgs,
        [Parameter(Mandatory)]
        [string] $Description
    )

    Write-Message -Message "Converting $Description" -Type Processing
    $ffmpegArgs = New-Object System.Collections.Generic.List[string]
    $ffmpegArgs.AddRange($BaseArgs)
    if ($AudioArgs) {
        $ffmpegArgs.AddRange($AudioArgs)
    }
    if ($FinalArgs) {
        $ffmpegArgs.AddRange($FinalArgs)
    }
    $ffmpegArgsArray = $ffmpegArgs.ToArray()

    Write-Message "Arguments: $($ffmpegArgsArray -join ' ')" -Type Info
    $result = Invoke-FFMpeg $ffmpegArgsArray
    if ($result.ExitCode -ne 0) {
        throw "Encode $Description failed (ExitCode: $($result.ExitCode)): $($result.Error)"
    }

    Write-Message -Message "Convert $Description completed" -Type Success
}
