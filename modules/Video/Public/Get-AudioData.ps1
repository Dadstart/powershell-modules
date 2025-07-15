function Get-AudioData {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Gets audio stream information from MKV files in the current directory.

    .DESCRIPTION
        This function scans the current directory for MKV files and extracts detailed
        information about all audio streams found in each file. It provides information
        about language, codec, title, and channel configuration for each audio stream.

    .PARAMETER None
        This function does not accept any parameters. It operates on MKV files in the current directory.

    .EXAMPLE
        Get-AudioData

        Gets audio stream information from all MKV files in the current directory.

    .EXAMPLE
        Get-AudioData | Where-Object { $_.Language -eq 'eng' }

        Gets audio stream information and filters to show only English audio streams.

    .EXAMPLE
        Get-AudioData | Format-Table -AutoSize

        Gets audio stream information and displays it in a formatted table.

    .OUTPUTS
        [PSCustomObject[]] - Array of objects containing audio stream information:
        - File: Name of the MKV file
        - Language: Audio language code (e.g., 'eng', 'spa')
        - Codec: Audio codec name (e.g., 'aac', 'ac3', 'dts')
        - Title: Audio stream title from metadata
        - Channels: Number of audio channels

    .NOTES
        This function requires the Video module to be loaded and depends on the
        Get-MediaStreams function for stream extraction.

    .LINK
        Get-MediaStreams
        Show-AudioData
    #>
    param()

    return Invoke-WithErrorHandling -OperationName 'Audio data extraction' -DefaultReturnValue @() -ErrorEmoji '🎵' -ScriptBlock {
        Write-Message 'Getting all MKV files in current directory' -Type Verbose
        $videos = Get-ChildItem *.mkv
        Write-Message "Found $($videos.Count) MKV files" -Type Verbose
        
        if ($videos.Count -eq 0) {
            Write-Message "No MKV files found in current directory" -Type Warning
            return @()
        }
        
        # Use Get-MediaStreamCollection for efficient processing
        $videoPaths = $videos | Select-Object -ExpandProperty FullName
        Write-Message "Processing $($videoPaths.Count) files using Get-MediaStreamCollection" -Type Verbose
        
        $streamCollection = Get-MediaStreamCollection -Paths $videoPaths -Type Audio
        
        if (-not $streamCollection -or $streamCollection.Count -eq 0) {
            Write-Message "No audio streams found in any files" -Type Verbose
            return @()
        }
        
        $results = @()
        
        # Start progress tracking for video processing
        $videoProgress = Start-ProgressActivity -Activity 'Video Processing' -Status 'Processing video files...' -TotalItems $streamCollection.Count
        $currentVideo = 0
        
        foreach ($fileEntry in $streamCollection.GetEnumerator()) {
            $currentVideo++
            $videoPath = $fileEntry.Key
            $streams = $fileEntry.Value
            $videoName = [System.IO.Path]::GetFileName($videoPath)
            
            $videoProgress.Update(@{
                    CurrentItem = $currentVideo
                    Status      = "Processing: $videoName"
                })
            
            Write-Message "Processing video file: $videoName" -Type Verbose
            Write-Message "Found $($streams.Count) audio streams in $videoName" -Type Verbose
            
            # Start progress tracking for stream processing within this video
            $streamProgress = Start-ProgressActivity -Activity 'Stream Processing' -Status 'Processing audio streams...' -TotalItems $streams.Count -Id 2 -ParentId 1
            $currentStream = 0
            
            foreach ($stream in $streams) {
                $currentStream++
                $streamProgress.Update(@{
                        CurrentItem = $currentVideo
                        Status      = "Processing stream $currentStream of $($streams.Count)"
                    })
                
                Write-Message "Processing audio stream: Index=$($stream.Index), TypeIndex=$($stream.TypeIndex), CodecType=$($stream.CodecType), CodecName=$($stream.CodecName)" -Type Verbose
                $result = [PSCustomObject]@{
                    SourceFile = $videoName
                    Language   = $stream.Language
                    Codec      = $stream.CodecName
                    Title      = $stream.Title
                    Channels   = $stream.Stream.channels
                }
                $results += $result
                Write-Message "$videoName`: [$($stream.Index)] [$($stream.TypeIndex)] $($stream.CodecType) $($stream.CodecName) $($stream.Title)" -Type Verbose
            }
            
            $streamProgress.Stop(@{ Status = "Stream processing completed for $videoName" })
        }
        
        $videoProgress.Stop(@{ Status = 'Video processing completed' })
        
        return $results
    }
} 
