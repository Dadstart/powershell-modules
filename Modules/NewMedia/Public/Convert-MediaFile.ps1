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
        [Parameter(Mandatory)][object[]] $AudioMappings,
        [Parameter()][hashtable] $AdditionalArgs
    )
    begin {
        @('Write-Message', 'Invoke-FFMpeg', 'Invoke-Process') | ForEach-Object {
            $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
        }
    }
    process {
        Test-FFMpegInstalled -Throw

        # Base arguments hashtable
        $baseArgs = [ordered]@{
            '-y' = $null
        }
        foreach ($inputFile in $InputFiles) {
            $baseArgs['-i'] = $inputFile
        }

        # Audio arguments hashtable
        $audioArgs = [ordered]@{}
        foreach ($am in $AudioMappings) {
            $ffmpegArgs = $am.ToFfmpegArgs()
            Add-OrderedHashtable -TargetHashtable $audioArgs -SourceHashtable $ffmpegArgs
        }

        if ($VideoSettings.Bitrate) {
            $passLogFile = [System.IO.Path]::ChangeExtension($OutputFile, '.ffmpeg')

            # Pass 1 arguments hashtable
            $pass1Args = [ordered]@{}

            Add-OrderedHashtable -TargetHashtable $pass1Args -SourceHashtable $baseArgs
            $videoArgs = $VideoSettings.ToFfMpegArgs(1, $passLogFile)
            Add-OrderedHashtable -TargetHashtable $pass1Args -SourceHashtable $videoArgs
            $pass1Args['-an'] = $null
            $pass1Args['-sn'] = $null

            # Pass 1 final arguments hashtable
            $pass1FinalArgs = [ordered]@{
                '-f'  = 'null'
                'NUL' = $null
            }
            Convert-MediaFileFromArgumentList -ArgumentHashtables @($pass1Args, $pass1FinalArgs) -Description 'VBR Pass 1'

            # Pass 2 arguments hashtable
            $pass2Args = [ordered]@{}
            Add-OrderedHashtable -TargetHashtable $pass2Args -SourceHashtable $baseArgs
            $videoArgs = $VideoSettings.ToFfMpegArgs(2, $passLogFile)
            Add-OrderedHashtable -TargetHashtable $pass2Args -SourceHashtable $videoArgs

            # Pass 2 final arguments hashtable
            $pass2FinalArgs = [ordered]@{}
            Add-OrderedHashtable -TargetHashtable $pass2FinalArgs -SourceHashtable $AdditionalArgs
            $pass2FinalArgs[$OutputFile] = $null

            Convert-MediaFileFromArgumentList -ArgumentHashtables @($pass2Args, $audioArgs, $pass2FinalArgs) -Description 'VBR Pass 2'
        }
        else {
            # CRF final arguments hashtable
            $finalArgs = $VideoSettings.ToFfMpegArgs(0, $null)
            Add-OrderedHashtable -TargetHashtable $finalArgs -SourceHashtable $AdditionalArgs
            $finalArgs[$OutputFile] = $null

            Convert-MediaFileFromArgumentList -ArgumentHashtables @($baseArgs, $audioArgs, $finalArgs) -Description 'CRF'
        }
    }
}



function Convert-MediaFileFromArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable[]] $ArgumentHashtables,
        [Parameter(Mandatory)]
        [string] $Description
    )

    Write-Message -Message "Converting $Description" -Type Processing
    $ffmpegArgs = New-Object System.Collections.Generic.List[string]

    # Process each hashtable in order
    foreach ($hashtable in $ArgumentHashtables) {
        Add-HashtableArgs -FinalArgs $ffmpegArgs -AdditionalArgs $hashtable
    }

    $ffmpegArgsArray = $ffmpegArgs.ToArray()

    Write-Message "Arguments: $($ffmpegArgsArray -join ' ')" -Type Info
    $result = Invoke-FFMpeg $ffmpegArgsArray
    if ($result.ExitCode -ne 0) {
        throw "Encode $Description failed (ExitCode: $($result.ExitCode)): $($result.Error)"
    }

    Write-Message -Message "Convert $Description completed" -Type Success
}
