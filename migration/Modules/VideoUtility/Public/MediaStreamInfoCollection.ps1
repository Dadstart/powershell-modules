class MediaStreamInfoCollection {
    <#
    .SYNOPSIS
        A collection of MediaStreamInfo arrays organized by file path.

    .DESCRIPTION
        This class provides a dictionary-like interface for storing and managing
        arrays of MediaStreamInfo objects, organized by file path. Each file (key)
        can contain multiple media streams (value as array). It supports all standard
        dictionary operations including Add, Remove, ContainsKey, and indexing.

    .PROPERTY Count
        The number of files in the collection.

    .PROPERTY Keys
        A collection of all file paths in the dictionary.

    .PROPERTY Values
        A collection of all MediaStreamInfo arrays in the dictionary.

    .EXAMPLE
        $collection = [MediaStreamInfoCollection]::new()
        $streams = Get-MediaStreams "video.mkv"
        $collection.Add("C:\videos\video.mkv", $streams)
        
        if ($collection.ContainsKey("C:\videos\video.mkv")) {
            $fileStreams = $collection["C:\videos\video.mkv"]
            $audioStreams = $fileStreams | Where-Object { $_.IsAudio() }
        }

    .EXAMPLE
        $collection = [MediaStreamInfoCollection]::new()
        $collection["C:\videos\video1.mkv"] = Get-MediaStreams "C:\videos\video1.mkv"
        $collection["C:\videos\video2.mkv"] = Get-MediaStreams "C:\videos\video2.mkv"
        
        foreach ($filePath in $collection.Keys) {
            $streams = $collection[$filePath]
            Write-Host "File: $filePath has $($streams.Count) streams"
        }

    .NOTES
        This class is designed to work seamlessly with PowerShell's dictionary-like
        syntax while organizing MediaStreamInfo objects by their source files.
    #>

    # Private dictionary to store the key-value pairs
    # Keys: File paths (strings)
    # Values: Arrays of MediaStreamInfo objects
    hidden [System.Collections.Generic.Dictionary[string, object[]]]$Dictionary

    # Constructor
    MediaStreamInfoCollection() {
        $this.Dictionary = [System.Collections.Generic.Dictionary[string, object[]]]::new()
    }

    # Property: Count
    [int]get_Count() {
        return $this.Dictionary.Count
    }

    # Property: Keys
    [object]get_Keys() {
        return $this.Dictionary.Keys
    }

    # Property: Values
    [object[]]get_Values() {
        return $this.Dictionary.Values
    }

    # Indexer for getting and setting values
    [object[]]get_Item([string]$Key) {
        return $this.Dictionary[$Key]
    }

    [void]set_Item([string]$Key, $Value) {
        $this.Dictionary[$Key] = $Value
    }

    # Method: Add
    Add([string]$Key, $Value) {
        $this.Dictionary[$Key] = $Value
    }

    # Method: Remove
    [bool]Remove([string]$Key) {
        if ($this.Dictionary.ContainsKey($Key)) {
            $this.Dictionary.Remove($Key)
            return $true
        }
        return $false
    }

    # Method: Clear
    [void]Clear() {
        $this.Dictionary.Clear()
    }

    # Method: ContainsKey
    [bool]ContainsKey([string]$Key) {
        return $this.Dictionary.ContainsKey($Key)
    }

    # Method: ContainsValue
    [bool]ContainsValue($Value) {
        return $this.Dictionary.Values -contains $Value
    }

    # Method: TryGetValue
    [bool]TryGetValue([string]$Key, [ref]$Value) {
        if ($this.Dictionary.ContainsKey($Key)) {
            $Value.Value = $this.Dictionary[$Key]
            return $true
        }
        $Value.Value = $null
        return $false
    }

    # Method: GetEnumerator (for foreach loops)
    [object]GetEnumerator() {
        return $this.Dictionary.GetEnumerator()
    }

    # Method: GetAudioStreams
    [object[]]GetAudioStreams() {
        $allAudioStreams = @()
        foreach ($streamArray in $this.Dictionary.Values) {
            $allAudioStreams += $streamArray | Where-Object { $_.IsAudio() }
        }
        return $allAudioStreams
    }

    # Method: GetVideoStreams
    [object[]]GetVideoStreams() {
        $allVideoStreams = @()
        foreach ($streamArray in $this.Dictionary.Values) {
            $allVideoStreams += $streamArray | Where-Object { $_.IsVideo() }
        }
        return $allVideoStreams
    }

    # Method: GetSubtitleStreams
    [object[]]GetSubtitleStreams() {
        $allSubtitleStreams = @()
        foreach ($streamArray in $this.Dictionary.Values) {
            $allSubtitleStreams += $streamArray | Where-Object { $_.IsSubtitle() }
        }
        return $allSubtitleStreams
    }

    # Method: GetDataStreams
    [object[]]GetDataStreams() {
        $allDataStreams = @()
        foreach ($streamArray in $this.Dictionary.Values) {
            $allDataStreams += $streamArray | Where-Object { $_.IsData() }
        }
        return $allDataStreams
    }

    # Method: GetStreamsByLanguage
    [object]GetStreamsByLanguage([string]$Language) {
        $allStreamsOfLanguage = @()
        foreach ($streamArray in $this.Dictionary.Values) {
            $allStreamsOfLanguage += $streamArray | Where-Object { $_.Language -eq $Language }
        }
        return $allStreamsOfLanguage
    }

    # Method: ExportFile
    [void]ExportFile([string]$File, [string]$OutputDirectory, [string]$Language, [string]$Type, [switch]$Force) {
        if (-not (Test-Path $OutputDirectory)) {
            if ($Force) {
                New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
            }
            else {
                Write-Error "Output directory $OutputDirectory does not exist. Use -Force to create it."
            }
        }

        if (-not $this.Dictionary.ContainsKey($File)) {
            Write-Error "File $File not found in collection"
        }

        $streams = $this.Dictionary[$File]
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($File)
        $outputFiles = @()
        $fileFFMpegArgs = @()

        foreach ($stream in $streams) {
            if ($Language -and $stream.Language -ne $Language) {
                continue
            }
            if ($Type -and $stream.CodecType -ne $Type) {
                continue
            }

            # Use Get-MediaExtension for proper extension mapping
            $extension = Get-MediaExtension -CodecType $stream.CodecType -CodecName $stream.CodecName
            $streamKey = "$($stream.CodecType)_$($stream.TypeIndex)"
            if ($stream.Language) {
                $streamKey += "_$($stream.Language)"
            }
            $outputFile = Join-Path $OutputDirectory "$fileName`_$streamKey.$extension"
            $fileFFMpegArgs += $stream.GetFFMpegOutputArgs($outputFile)
        }

        $quotedInputPath = '"' + $File + '"'
        $fileFFMpegArgs += @('-i', $quotedInputPath, '-y')
        $result = Invoke-FFMpeg -Arguments $fileFFMpegArgs

        if ($result.ExitCode -ne 0) {
            Write-Error "Failed to export streams for file '$File'"
        }
    }

    # Method: ExportAllStreams
    [void]ExportAllStreams([string]$OutputDirectory, [string]$Language, [string]$Type, [switch]$Force) {
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force:$Force | Out-Null
        }

        foreach ($filePath in $this.Dictionary.Keys) {
            $this.ExportFile($filePath, $OutputDirectory, $Language, $Type, $Force)
        }
    }

    # Method: GetFFMpegArgsForStreams - returns ffmpeg arguments for multiple streams from same file
    [string[]]GetFFMpegArgsForStreams([string]$FilePath, [string[]]$OutputPaths, [int[]]$StreamIndices) {
        if (-not $this.ContainsKey($FilePath)) {
            Write-Error "File '$FilePath' not found in collection" -ErrorAction Stop
        }

        $streamArray = $this.Dictionary[$FilePath]
        if ($streamArray.Count -eq 0) {
            Write-Error "No streams found for file '$FilePath'" -ErrorAction Stop
        }

        # Build combined ffmpeg arguments for multiple streams
        $quotedInputPath = '"' + $FilePath + '"'
        $ffmpegArgs = @('-i', $quotedInputPath, '-y')
        
        for ($i = 0; $i -lt $StreamIndices.Count; $i++) {
            $streamIndex = $StreamIndices[$i]
            $outputPath = $OutputPaths[$i]
            
            if ($streamIndex -ge $streamArray.Count) {
                Write-Error "Stream index $streamIndex out of range for file '$FilePath'" -ErrorAction Stop
            }
            
            $stream = $streamArray[$streamIndex]
            $ffmpegArgs += $stream.GetFFMpegOutputArgs($outputPath) 
        }
        
        return $ffmpegArgs
    }

    # Override ToString method for better debugging
    [string]ToString() {
        return "MediaStreamInfoCollection{Count=$($this.Dictionary.Count)}"
    }

    # Static method: Create from MediaStreamInfo array
    static [MediaStreamInfoCollection]FromStreams([object[]]$Streams) {
        $collection = [MediaStreamInfoCollection]::new()
        
        # Group streams by their source file
        $streamsByFile = $Streams | Group-Object -Property SourceFile
        
        foreach ($fileGroup in $streamsByFile) {
            $filePath = $fileGroup.Name
            $streamArray = $fileGroup.Group
            $collection.Add($filePath, $streamArray)
        }
        
        return $collection
    }
}