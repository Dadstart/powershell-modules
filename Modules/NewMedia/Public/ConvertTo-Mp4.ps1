function ConvertTo-Mp4 {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $InputDirectory
    )

    @('Convert-MediaFile', 'Write-Message', 'Invoke-FFMpeg', 'Invoke-Process') | ForEach-Object {
        $PSDefaultParameterValues["$_`:Verbose"] = $VerbosePreference
        $PSDefaultParameterValues["$_`:Debug"] = $DebugPreference
    }

    Write-Message "📂 Converting directory: $InputDirectory" -Type Processing

    $inputDir = Get-Path $InputDirectory -PathType Absolute
    Write-Message "`t📁 InputDir:  $inputDir" -Type Info
    $outputDir = Get-Path @($inputDir, 'MP4') -PathType Absolute -Create Directory
    Write-Message "`t📁 OutputDir: $outputDir" -Type Info

    # $videoSettings = New-VideoEncodingSettings -Codec x264 -CRF 21 -Preset slow -CodecProfile high -Tune film
    $videoSettings = New-VideoEncodingSettings -Codec x264 -Bitrate 5000 -Preset slow
    $audioMapping0 = New-AudioTrackMapping -SourceIndex 0 -DestinationIndex 1 -CopyOriginal -Title 'DTS-HD'
    $audioMapping1 = New-AudioTrackMapping -SourceIndex 1 -DestinationIndex 0 -DestinationCodec aac -DestinationChannels 6 -Title 'Surround 5.1'
    Write-Message "`t🎥 Video settings: $($videoSettings.ToFfmpegArgs(1) -join ' ')" -Type Info
    Write-Message "`t🎧 Audio mapping 0: $($audioMapping0.ToFfmpegArgs() -join ' ')" -Type Info
    Write-Message "`t🎧 Audio mapping 1: $($audioMapping1.ToFfmpegArgs() -join ' ')" -Type Info

    $allFiles = Get-ChildItem $inputDir *.mkv
    Write-Message "🔁 Converting $($allFiles.Count) files" -Type Processing
    $allFiles | ForEach-Object {
        Write-Message "`tProcessing: $($_.BaseName)" -Type Processing

        $outputFileName = (Get-Path $_ -PathType LeafBase) + '.mp4'
        $outputFile = Get-Path @($outputDir, $outputFileName) -PathType Absolute
        Write-Message "`t📁 OutputFile: $outputFile" -Type Info

        if ($PSCmdlet.ShouldProcess($_.FullName, "Convert to MP4")) {
            Convert-MediaFile -InputFiles $_.FullName -OutputFile $outputFile -VideoSettings $videoSettings -AudioMappings @($audioMapping0, $audioMapping1)
        }
    }

    Write-Message '✅ Directory conversion completed' -Type Success
}