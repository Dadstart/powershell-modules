function Get-FilteredAudioStreams {
    <#
    .SYNOPSIS
        Processes video files and filters audio streams by language, returning organized results.
    .DESCRIPTION
        Analyzes video files in the input directory, extracts audio streams, filters by language,
        and returns organized results including valid streams and skipped files. This centralizes
        the common audio stream processing logic used across multiple functions.
        The function now works with MediaStreamInfo objects and uses Get-MediaStreamCollection
        for efficient processing of multiple files.
    .PARAMETER Path
        The directory containing video files to process.
    .PARAMETER Language
        The language code for audio streams to process. Default is 'eng'.
    .PARAMETER Count
        The maximum number of audio streams to process per file. Default is 1.
    .EXAMPLE
        $result = Get-FilteredAudioStreams -Path "C:\Videos" -Language "eng"
        $result  # Valid streams hashtable
    .OUTPUTS
        Hashtable of valid audio streams indexed by file. Each stream object is a MediaStreamInfo
        object with the following properties:
            - SourceFile: Full path to the file
            - Index: Stream index within the file
            - CodecType: Type of stream (audio)
            - CodecName: Name of the codec
            - TypeIndex: Index within the stream type
            - Language: Language code
            - Title: Stream title
            - Disposition: Stream disposition flags
            - Tags: Additional metadata tags
    .NOTES
        This function now works with MediaStreamInfo objects which provide methods like
        IsAudio(), GetDisplayName(), and ToString() for easier stream manipulation.
        It uses Get-MediaStreamCollection for efficient processing of multiple files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    $skippedFiles = @()
    $result = @{}
    # Get all MKV files in the directory
    $mkvFiles = Get-ChildItem -Path $Path -Filter *.mkv -File
    if ($mkvFiles.Count -eq 0) {
        Write-Message "No MKV files found in directory: $Path" -Type Warning
        return $result
    }
    Write-Message "Processing $($mkvFiles.Count) MKV files using Get-MediaStreamCollection" -Type Verbose
    # Use Get-MediaStreamCollection for efficient processing
    $filePaths = $mkvFiles | Select-Object -ExpandProperty FullName
    $streamCollection = $filePaths | Get-MediaStreamCollection -Type Audio
    if (-not $streamCollection -or $streamCollection.Count -eq 0) {
        Write-Message 'No audio streams found in any files' -Type Verbose
        return $result
    }
    foreach ($fileEntry in $streamCollection.GetEnumerator()) {
        $filePath = $fileEntry.Key
        $streams = $fileEntry.Value
        $fileName = [System.IO.Path]::GetFileName($filePath)
        Write-Message "File: $fileName" -Type Debug
        Write-Message "$fileName`: Audio Streams ($($streams.Count)): $($($streams | ForEach-Object { $_.GetDisplayName() }) -join ', ')" -Type Verbose
        $languageStreams = $streams | Where-Object { $_.Language -eq $Language }
        Write-Message "$fileName`: $Language audio Streams ($($languageStreams.Count)): $($($languageStreams | ForEach-Object { $_.GetDisplayName() }) -join ', ')" -Type Verbose
        Write-Message "Language Streams: $($languageStreams | ConvertTo-Json -Compress)" -Type Debug
        if (-not $languageStreams -or ($languageStreams.Count -eq 0)) {
            Write-Message "Zero $Language audio streams found for $fileName" -Type Verbose
            $currentStreams = @()
        }
        elseif ($languageStreams.Count -gt $Count) {
            $skippedFiles += $filePath
            Write-Message "Multiple $Language audio streams found for $fileName" -Type Verbose
            Write-Message "Skipping $fileName due to >$($Count) ($($languageStreams.Count)) $Language audio streams" -Type Warning
            continue
        }
        else {
            $currentStreams = $languageStreams
            Write-Message "Multiple $Language audio streams ($($currentStreams.Count)) found for $fileName" -Type Verbose
        }
        Write-Message "Adding to result: $fileName with $($currentStreams.Count) streams" -Type Verbose
        $result[$filePath] = @{
            'File'    = $filePath
            'Streams' = $currentStreams
        }
    }
    return $result
}
