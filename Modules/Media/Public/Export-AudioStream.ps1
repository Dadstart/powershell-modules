function Export-AudioStream {
    <#
    .SYNOPSIS
        Exports audio streams from video files to external audio files.
    .DESCRIPTION
        This function takes audio stream objects (from Get-AudioStream) and exports them
        to external audio files using Export-MediaStream. It supports batch processing of
        multiple streams and provides detailed progress reporting.
    .PARAMETER AudioStreams
        Array of audio stream objects from Get-AudioStream. Accepts pipeline input.
    .PARAMETER OutputDirectory
        Directory where exported audio files will be saved. If not specified, uses the
        same directory as the source video file.
    .PARAMETER OutputFormat
        Format for the exported audio files. Common formats include 'aac', 'ac3', 'mp3'.
        If not specified, uses the original codec format.
    .PARAMETER Force
        Overwrites existing audio files without prompting.
    .PARAMETER WhatIf
        Shows what would be exported without actually performing the export.
    .EXAMPLE
        Get-AudioStream -Source .\Season01 -Language eng | Export-AudioStream -OutputDirectory .\Audio
        Gets all English audio streams from Season01 directory and exports them to an Audio folder.
    .EXAMPLE
        Get-AudioStream -Source .\movie.mkv -CodecName aac | Export-AudioStream -OutputFormat mp3
        Gets AAC audio streams from movie.mkv and exports them as MP3 files in the same directory.
    .EXAMPLE
        $streams = Get-AudioStream -Source .\videos -Language eng
        $streams | Export-AudioStream -OutputDirectory .\exports -Force
        Gets English audio streams, then exports them to an exports directory, overwriting existing files.
    .OUTPUTS
        [PSCustomObject[]] - Array of export result objects containing:
        - SourceFile: Original video file path
        - OutputFile: Path to the exported audio file
        - StreamIndex: Index of the exported stream
        - Language: Language code of the audio
        - CodecName: Original codec name
        - Success: Boolean indicating if export was successful
        - ErrorMessage: Error message if export failed
    .NOTES
        This function requires the Video module to be loaded and depends on Get-AudioStream
        for stream discovery and Export-MediaStream for actual export operations.
    .LINK
        Get-AudioStream
        Export-MediaStream
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [PSCustomObject[]]$AudioStreams,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDirectory,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFormat,
        [Parameter()]
        [switch]$Force
    )
    begin {
        @(
            'Write-Message',
            'Get-Path',
            'Start-ProgressActivity',
            'Get-AudioStream',
            'Get-MediaExtension',
            'Export-MediaStream',
            'ConvertTo-MediaStreamCollection',
            'Export-MediaStreamCollection'
        ) | Set-PreferenceInheritance
        $allResults = @()
        $processedCount = 0
        $skippedCount = 0
        $errorCount = 0
        Write-Message '🎵 Starting audio stream export' -Type Processing
        # Validate output directory if specified
        if ($OutputDirectory) {
            $OutputDirectory = Get-Path -Path $OutputDirectory -PathType Absolute -Create Directory
            Write-Message "Output directory: $OutputDirectory" -Type Verbose
        }
    }
    process {
        # Filter for audio streams
        $audioStreams = $AudioStreams | Where-Object { $_.IsAudio() }
        if ($audioStreams.Count -eq 0) {
            Write-Message "No valid audio streams found" -Type Warning
            return
        }
        # If OutputDirectory is specified, use Export-MediaStreamCollection for efficiency
        if ($OutputDirectory) {
            Write-Message "Using Export-MediaStreamCollection for batch export" -Type Verbose
            # Convert to MediaStreamInfoCollection
            $streamCollection = ConvertTo-MediaStreamCollection -Streams $audioStreams
            # Export using the collection function
            $exportResults = Export-MediaStreamCollection -StreamCollection $streamCollection -Type Audio -Language $Language -OutputDirectory $OutputDirectory -OutputFormat $OutputFormat -Force:$Force
            # Process results
            foreach ($result in $exportResults) {
                if ($result.Success) {
                    $processedCount++
                    Write-Message "✅ Successfully exported: $($result.OutputFile)" -Type Success
                } else {
                    $errorCount++
                    Write-Message "❌ Failed to export: $($result.ErrorMessage)" -Type Error
                }
            }
            return $exportResults
        }
        # Fall back to individual processing if no OutputDirectory specified
        $progress = Start-ProgressActivity -Activity 'Exporting audio streams' -Status 'Processing streams...' -TotalItems $audioStreams.Count
        $streamIndex = 0
        foreach ($stream in $audioStreams) {
            $streamIndex++
            try {
                $progress.Update(@{ CurrentItem = $streamIndex; Status = "Processing stream $streamIndex" })
                Write-Message "Processing audio stream: Index=$($stream.Index), TypeIndex=$($stream.TypeIndex), CodecName=$($stream.CodecName)" -Type Verbose
                # Validate stream object is MediaStreamInfo
                if ($stream.GetType().Name -ne 'MediaStreamInfo') {
                    Write-Message "Stream object is not a MediaStreamInfo object" -Type Warning
                    $skippedCount++
                    continue
                }
                # validate stream object
                if (-not $stream.SourceFile) {
                    Write-Message 'Stream object does not contain source file information' -Type Warning
                    $skippedCount++
                    continue
                }
                if ($null -eq $stream.TypeIndex) {
                    Write-Message 'Stream object does not contain type index information' -Type Warning
                    $skippedCount++
                    continue
                }
                if (-not $stream.CodecName) {
                    Write-Message 'Stream object does not contain codec name information' -Type Warning
                    $skippedCount++
                    continue
                }
                if (-not $stream.IsAudio()) {
                    Write-Message 'Stream object is not an audio stream' -Type Warning
                    $skippedCount++
                    continue
                }
                # Build output filename
                $sb = [System.Text.StringBuilder]::new()
                $sb.Append([System.IO.Path]::GetFileNameWithoutExtension($stream.SourceFile))
                if ($stream.Language) {
                    $sb.Append(".$($stream.Language)")
                }
                $sb.Append(".$($stream.TypeIndex)")
                if ($OutputFormat) {
                    $sb.Append(".$OutputFormat")
                }
                else {
                    $extension = Get-MediaExtension -CodecType Audio -CodecName $stream.CodecName
                    $sb.Append($extension)
                }
                $outputFileName = $sb.ToString()                
                Write-Message "OutputFileName: $outputFileName" -Type Verbose
                # Determine output directory
                $finalOutputDir = if ($OutputDirectory) { $OutputDirectory } else { [System.IO.Path]::GetDirectoryName($stream.SourceFile) }
                $outputPath = Get-Path -Path $finalOutputDir, $outputFileName -PathType Absolute
                # Check if output file exists
                if (Test-Path $outputPath -ErrorAction SilentlyContinue) {
                    if (-not $Force) {
                        Write-Message "Output file already exists: $outputPath" -Type Warning
                        $skippedCount++
                        continue
                    }
                    else {
                        Write-Message "Deleting existing file: $outputPath" -Type Verbose
                        Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
                    }
                }
                # Export the audio stream
                if ($PSCmdlet.ShouldProcess("$($stream.SourceFile) ➡️ $outputPath", 'Export audio stream')) {
                    Write-Message "Exporting audio stream $($stream.TypeIndex) from $($stream.SourceFile)" -Type Processing
                    # Remove existing file if Force is specified
                    if ($Force -and (Test-Path $outputPath)) {
                        Remove-Item $outputPath -Force -ErrorAction SilentlyContinue
                    }
                    # Export using Export-MediaStream
                    Export-MediaStream -InputPath $stream.SourceFile -Type Audio -Index $stream.TypeIndex -OutputPath $outputPath
                    # Verify export was successful
                    if (Test-Path $outputPath -ErrorAction SilentlyContinue) {
                        $fileSize = (Get-Item $outputPath).Length
                        Write-Message "✅ Successfully exported audio to: $outputPath (Size: $($fileSize / 1mb) mb)" -Type Success
                        $result = [PSCustomObject]@{
                            SourceFile   = $stream.SourceFile
                            OutputFile   = $outputPath
                            StreamIndex  = $stream.TypeIndex
                            Language     = $stream.Language
                            CodecName    = $stream.CodecName
                            Success      = $true
                            ErrorMessage = $null
                            FileSize     = $fileSize
                        }
                        $allResults += $result
                        $processedCount++
                    }
                    else {
                        throw 'Export completed but output file was not created'
                    }
                }
                else {
                    Write-Message "WhatIf mode - would export audio stream $($stream.TypeIndex) from $sourceFile to $outputPath" -Type Verbose
                    $skippedCount++
                }
            }
            catch {
                $errorMessage = "Failed to export audio stream: $($_.Exception.Message)"
                Write-Message $errorMessage -Type Error
                $result = [PSCustomObject]@{
                    SourceFile   = $stream.SourceFile
                    OutputFile   = $outputPath
                    StreamIndex  = $stream.TypeIndex
                    Language     = $stream.Language
                    CodecName    = $stream.CodecName
                    Success      = $false
                    ErrorMessage = $errorMessage
                    FileSize     = 0
                }
                $allResults += $result
                $errorCount++
            }
        }
    }
    end {
        # Export summary
        Write-Message "`n📊 === Audio Export Summary ===" -Type Processing
        Write-Message "✅ Successfully exported: $processedCount" -Type Success
        Write-Message "⏭️ Skipped: $skippedCount" -Type Warning
        Write-Message "❌ Errors: $errorCount" -Type $(if ($errorCount -gt 0) { 'Error' } else { 'Info' })
        if ($OutputDirectory) {
            Write-Message "📁 Output directory: $OutputDirectory" -Type Info
        }
        # Return results
        return $allResults
    }
} 
