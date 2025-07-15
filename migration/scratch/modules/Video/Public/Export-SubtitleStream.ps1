function Export-SubtitleStream {
    <#
    .SYNOPSIS
        Exports subtitle streams from video files to external subtitle files.

    .DESCRIPTION
        This function takes subtitle stream objects (from Get-SubtitleStream) and exports them
        to external subtitle files using Export-MediaStream. It supports batch processing of
        multiple streams and provides detailed progress reporting.

    .PARAMETER SubtitleStreams
        Array of subtitle stream objects from Get-SubtitleStream. Accepts pipeline input.

    .PARAMETER OutputDirectory
        Directory where exported subtitle files will be saved. If not specified, uses the
        same directory as the source video file.

    .PARAMETER OutputFormat
        Format for the exported subtitle files. Common formats include 'srt', 'ass', 'ssa'.
        If not specified, uses the original codec format.

    .PARAMETER Force
        Overwrites existing subtitle files without prompting.

    .PARAMETER WhatIf
        Shows what would be exported without actually performing the export.

    .EXAMPLE
        Get-SubtitleStream -Source .\Season01 -Language eng | Export-SubtitleStream -OutputDirectory .\Subtitles

        Gets all English subtitle streams from Season01 directory and exports them to a Subtitles folder.

    .EXAMPLE
        Get-SubtitleStream -Source .\movie.mkv -CodecName subrip | Export-SubtitleStream -OutputFormat srt

        Gets subrip subtitle streams from movie.mkv and exports them as SRT files in the same directory.

    .EXAMPLE
        $streams = Get-SubtitleStream -Source .\videos -Language eng
        $streams | Export-SubtitleStream -OutputDirectory .\exports -Force

        Gets English subtitle streams, then exports them to an exports directory, overwriting existing files.

    .OUTPUTS
        [PSCustomObject[]] - Array of export result objects containing:
        - SourceFile: Original video file path
        - OutputFile: Path to the exported subtitle file
        - StreamIndex: Index of the exported stream
        - Language: Language code of the subtitle
        - CodecName: Original codec name
        - Success: Boolean indicating if export was successful
        - ErrorMessage: Error message if export failed

    .NOTES
        This function requires the Video module to be loaded and depends on Get-SubtitleStream
        for stream discovery and Export-MediaStream for actual export operations.

    .LINK
        Get-SubtitleStream
        Export-MediaStream
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [PSCustomObject[]]$SubtitleStreams,

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
            'Get-SubtitleStream',
            'Get-MediaExtension',
            'Export-MediaStream',
            'ConvertTo-MediaStreamCollection',
            'Export-MediaStreamCollection'
        ) | Set-PreferenceInheritance
        
        $allResults = @()
        $processedCount = 0
        $skippedCount = 0
        $errorCount = 0

        Write-Message '📝 Starting subtitle stream export' -Type Processing
        
        # Validate output directory if specified
        if ($OutputDirectory) {
            $OutputDirectory = Get-Path -Path $OutputDirectory -PathType Absolute -Create Directory
            Write-Message "Output directory: $OutputDirectory" -Type Verbose
        }
    }

    process {
        # Filter for subtitle streams
        $subtitleStreams = $SubtitleStreams | Where-Object { $_.IsSubtitle() }
        if ($subtitleStreams.Count -eq 0) {
            Write-Message "No valid subtitle streams found" -Type Warning
            return
        }

        # If OutputDirectory is specified, use Export-MediaStreamCollection for efficiency
        if ($OutputDirectory) {
            Write-Message "Using Export-MediaStreamCollection for batch export" -Type Verbose
            
            # Convert to MediaStreamInfoCollection
            $streamCollection = ConvertTo-MediaStreamCollection -Streams $subtitleStreams
            
            # Export using the collection function
            $exportResults = Export-MediaStreamCollection -StreamCollection $streamCollection -Type Subtitle -Language $Language -OutputDirectory $OutputDirectory -OutputFormat $OutputFormat -Force:$Force
            
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
        $streamIndex = 0
        $progress = Start-ProgressActivity -Activity 'Exporting subtitle streams' -Status 'Processing streams...' -TotalItems $subtitleStreams.Count
        
        foreach ($stream in $subtitleStreams) {
            $streamIndex++
            try {
                $progress.Update(@{ CurrentItem = $streamIndex; Status = "Processing stream $($streamIndex)" })

                Write-Message "Processing subtitle stream: Index=$($stream.Index), TypeIndex=$($stream.TypeIndex), CodecName=$($stream.CodecName)" -Type Verbose

                # Validate stream object is MediaStreamInfo
                if ($stream.GetType().Name -ne 'MediaStreamInfo') {
                    Write-Message "Stream object is not a MediaStreamInfo object" -Type Warning
                    $skippedCount++
                    continue
                }

                # validate stream object
                $sourceFile = $stream.SourceFile
                if (-not $sourceFile) {
                    Write-Message "Stream object does not contain source file information" -Type Warning
                    $skippedCount++
                    continue
                }
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
                if (-not $stream.IsSubtitle()) {
                    Write-Message 'Stream object is not a subtitle stream' -Type Warning
                    $skippedCount++
                    continue
                }

                # Determine output file path
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($stream.SourceFile)
                $streamLanguage = $stream.Language ?? 'unknown'
                $streamCodec = $stream.CodecName ?? 'unknown'
                $typeIndex = $stream.TypeIndex ?? 'unknown'
                
                # Build output filename
                $sb = [System.Text.StringBuilder]::new()
                $sb.Append($baseName)
                $sb.Append(".$streamLanguage")
                $sb.Append(".$typeIndex")
                if ($OutputFormat) {
                    $sb.Append(".$OutputFormat")
                } else {
                    $extension = Get-MediaExtension -CodecType Subtitle -CodecName $streamCodec
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

                # Export the subtitle stream
                if ($PSCmdlet.ShouldProcess("$($stream.SourceFile) ➡️ $outputPath", 'Export subtitle stream')) {
                    Write-Message "Exporting subtitle stream $($stream.TypeIndex) from $($stream.SourceFile)" -Type Processing
                    
                    # Export using Export-MediaStream
                    Export-MediaStream -InputPath $stream.SourceFile -Type Subtitle -Index $stream.TypeIndex -OutputPath $outputPath

                    # Verify export was successful
                    if (Test-Path $outputPath -ErrorAction SilentlyContinue) {
                        $fileSize = (Get-Item $outputPath).Length
                        Write-Message "✅ Successfully exported subtitle to: $outputPath (Size: $($fileSize / 1mb) mb)" -Type Success
                        
                        $result = [PSCustomObject]@{
                            SourceFile   = $stream.SourceFile
                            OutputFile   = $outputPath
                            StreamIndex  = $stream.TypeIndex
                            Language     = $streamLanguage
                            CodecName    = $streamCodec
                            Success      = $true
                            ErrorMessage = $null
                            FileSize     = $fileSize
                        }
                        $allResults += $result
                        $processedCount++
                    }
                    else {
                        throw "Export completed but output file was not created"
                    }
                }
                else {
                    Write-Message "WhatIf mode - would export subtitle stream $($stream.TypeIndex) from $($stream.SourceFile) to $outputPath" -Type Verbose
                    $skippedCount++
                }
            }
            catch {
                $errorMessage = "Failed to export subtitle stream: $($_.Exception.Message)"
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
        $progress.Stop(@{ PercentComplete = 100; Status = "Completed processing streams." })
    }

    end {
        # Export summary
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