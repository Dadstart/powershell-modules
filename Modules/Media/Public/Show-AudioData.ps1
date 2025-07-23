function Show-AudioData {
    <#
    .SYNOPSIS
        Displays audio stream information from video files.
    .DESCRIPTION
        This function extracts and displays audio stream information from video files
        using MediaStreamInfo objects. It provides a formatted output showing stream
        details including index, codec, language, and title information.
    .PARAMETER File
        The video file to analyze. Accepts pipeline input.
    .EXAMPLE
        Show-AudioData -File "movie.mkv"
        Displays all audio streams in the specified file.
    .EXAMPLE
        Get-ChildItem *.mkv | Show-AudioData
        Displays audio streams for all MKV files in the current directory.
    .NOTES
        This function requires the Video module to be loaded and depends on Get-MediaStreams for stream extraction.
        The function uses MediaStreamInfo objects which provide methods like GetDisplayName() and ToString()
        for better stream information display.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$File
    )
    process {
        try {
            Write-Message "Processing file: $File" -Type Verbose
            # Get the filename for display purposes
            $fileName = Get-Path -Path $File -PathType Leaf
            $streams = Get-MediaStreams -Path $File -Type Audio
            Write-Message "Found $($streams.Count) audio streams in $fileName" -Type Verbose
            foreach ($stream in $streams) {
                Write-Message "Processing audio stream: Index=$($stream.Index), TypeIndex=$($stream.TypeIndex), CodecType=$($stream.CodecType), CodecName=$($stream.CodecName)" -Type Verbose
                Write-Message "$fileName`: [$($stream.Index)] [$($stream.TypeIndex)] $($stream.CodecType) $($stream.CodecName) $($stream.Title)" -Type Info
            }
        }
        catch {
            Write-Message "Show-AudioData function failed with error: $($_.Exception.Message)" -Type Verbose
            Write-Message "Failed to write audio data for $File`: $($_.Exception.Message)" -Type Error
            throw "Failed to write audio data for $File`: $($_.Exception.Message)"
        }
    }
}
