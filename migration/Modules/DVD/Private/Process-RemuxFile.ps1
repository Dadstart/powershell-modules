function Process-RemuxFile {
    <#
    .SYNOPSIS
        Processes a single file pair for remuxing.
        
    .DESCRIPTION
        This function processes a single file pair for remuxing operations, extracting
        audio streams from HandBrake files and combining them with original video files.
        The function now works with MediaStreamInfo objects for better stream handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OriginalFile,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$HandbrakeFile,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TempDirectory
    )

    Write-Message "Remuxing original file with HandBrake file: $(Get-Path -Path $OriginalFile -PathType LeafBase)" -Type Processing
    Write-Message "Process-RemuxFile" -Type Verbose
    Write-Message "   OriginalFile: $OriginalFile" -Type Verbose
    Write-Message "   HandbrakeFile: $HandbrakeFile" -Type Verbose
    Write-Message "   Destination: $Destination" -Type Verbose
    Write-Message "   TempDirectory: $TempDirectory" -Type Verbose

    $originalFileName = Get-Path -Path $OriginalFile -PathType Leaf -ValidatePath File

    # create a new subdirectory for the output
            $tempSubDirectory = Get-Path -Path $TempDirectory, $originalFileName -PathType Absolute -Create Directory
    Write-Message "Created temp directory: $tempSubDirectory" -Type Verbose
    
    # Get the audio streams from the Handbrake file
    $resultStreams = @()

    $audioStreams = @(Get-MediaStreams -Path $handbrakeFile -Type Audio)
    
    foreach ($stream in $audioStreams) {
        $index = $stream.Index - 1
        Write-Message "Stream $index`: $($stream.CodecType); Codec: $($stream.CodecName); Language: $($stream.Language); Title: $($stream.Title)" -Type Verbose

                    $outputPath = Get-Path -Path $tempSubDirectory, "audio.$index.$($stream.CodecName)" -PathType Absolute

        Write-Message "Exporting stream $index to $outputPath" -Type Verbose
        Export-MediaStream -InputPath $handbrakeFile -Index $index -OutputPath $outputPath -Type Audio -Force | Out-Null

        $resultStream = [PSCustomObject]@{
            File = $outputPath
            Language = $stream.Language
            Title = $stream.Title
            Type = 'Audio'
        }
        Write-Message "Stream File: $($resultStream.File)" -Type Verbose
        Write-Message "Stream Language: $($resultStream.Language)" -Type Verbose
        Write-Message "Stream Title: $($resultStream.Title)" -Type Verbose
        Write-Message "Stream Type: $($resultStream.Type)" -Type Verbose
        $resultStreams += $resultStream
    }

    $remuxedFileName = [System.IO.Path]::ChangeExtension((Get-Path -Path $originalFileName -PathType Leaf), '.mkv')
            $remuxedFullName = Get-Path -Path $Destination, $remuxedFileName -PathType Absolute -ValidatePath File
    Write-Message "Remuxing to $remuxedFullName" -Type Verbose
    Add-MediaStream -InputPath $OriginalFile -Streams $resultStreams -OutputPath $remuxedFullName | Out-Null
} 
