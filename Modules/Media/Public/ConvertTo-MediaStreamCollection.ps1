function ConvertTo-MediaStreamCollection {
    <#
    .SYNOPSIS
        Converts MediaStreamInfo arrays to a MediaStreamInfoCollection.

    .DESCRIPTION
        This function takes one or more MediaStreamInfo arrays and converts them to a MediaStreamInfoCollection.
        It automatically groups streams by their SourceFile property, making it easy to organize streams
        from multiple files or convert existing Get-MediaStreams results.

    .PARAMETER InputObject
        One or more MediaStreamInfo objects or arrays of MediaStreamInfo objects to convert.

    .EXAMPLE
        $streams = Get-MediaStreams 'video.mkv'
        $collection = ConvertTo-MediaStreamCollection $streams
        # Converts the streams array to a MediaStreamInfoCollection.

    .EXAMPLE
        $streams1 = Get-MediaStreams 'video1.mkv'
        $streams2 = Get-MediaStreams 'video2.mkv'
        $collection = ConvertTo-MediaStreamCollection $streams1, $streams2
        # Combines streams from both files into a single collection.

    .EXAMPLE
        Get-MediaStreams '*.mp4' | ConvertTo-MediaStreamCollection
        # Converts streams from all MP4 files to a collection using pipeline.

    .EXAMPLE
        $collection = ConvertTo-MediaStreamCollection (Get-MediaStreams 'movie.mkv')
        $audioStreams = $collection.GetAudioStreams()
        $videoStreams = $collection.GetVideoStreams()
        # Converts and then uses collection methods to filter streams.

    .OUTPUTS
        [MediaStreamInfoCollection]
        Returns a MediaStreamInfoCollection where streams are organized by their SourceFile.

    .NOTES
        This function is useful for converting existing Get-MediaStreams results to use the new
        MediaStreamInfoCollection functionality. It automatically groups streams by their source file.
    #>
    [CmdletBinding()]
    [OutputType([MediaStreamInfoCollection])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [object[]]$InputObject
    )
    
    begin {
        $collection = [MediaStreamInfoCollection]::new()
    }
    
    process {
        foreach ($item in $InputObject) {
            if ($item -is [array]) {
                # Handle arrays of MediaStreamInfo objects
                foreach ($stream in $item) {
                    if ($stream -is [MediaStreamInfo]) {
                        $sourceFile = $stream.SourceFile
                        
                        if ($collection.ContainsKey($sourceFile)) {
                            # Add to existing array
                            $existingStreams = $collection[$sourceFile]
                            $existingStreams += $stream
                            $collection[$sourceFile] = $existingStreams
                        }
                        else {
                            # Create new array
                            $collection.Add($sourceFile, @($stream))
                        }
                    }
                }
            }
            elseif ($item -is [MediaStreamInfo]) {
                # Handle individual MediaStreamInfo objects
                $sourceFile = $item.SourceFile
                
                if ($collection.ContainsKey($sourceFile)) {
                    # Add to existing array
                    $existingStreams = $collection[$sourceFile]
                    $existingStreams += $item
                    $collection[$sourceFile] = $existingStreams
                }
                else {
                    # Create new array
                    $collection.Add($sourceFile, @($item))
                }
            }
            else {
                Write-Warning "Skipping item of type $($item.GetType().Name) - expected MediaStreamInfo"
            }
        }
    }
    
    end {
        return $collection
    }
} 