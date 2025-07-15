function Export-MediaStreamCollection {
    <#
    .SYNOPSIS
        Exports streams from a MediaStreamInfoCollection to files.

    .DESCRIPTION
        This function exports streams from a MediaStreamInfoCollection to the specified output directory.
        Each stream is saved with a filename that includes the original filename, stream type, type index,
        and language (if available).

    .PARAMETER Collection
        The MediaStreamInfoCollection containing streams to export.

    .PARAMETER OutputDirectory
        Directory where the extracted stream files will be saved. The directory will be created
        if it doesn't exist.

    .PARAMETER Type
        Type of streams to export. If not specified, exports all streams in the collection.
        Must be one of: Audio, Video, Subtitle, or Data.

    .PARAMETER Language
        Language code to filter streams by (e.g., 'eng', 'spa'). If not specified, exports all streams.

    .PARAMETER Force
        Overwrites existing output files without prompting. By default, the function skips
        files that already exist.

    .EXAMPLE
        $collection = Get-MediaStreamCollection 'movie1.mkv', 'movie2.mkv'
        Export-MediaStreamCollection -Collection $collection -OutputDirectory 'C:\extracted'
        # Exports all streams from both movies to 'C:\extracted'.

    .EXAMPLE
        $collection = Get-MediaStreamCollection 'video.mp4'
        Export-MediaStreamCollection -Collection $collection -OutputDirectory '.\audio' -Type Audio
        # Exports only audio streams from the collection to '.\audio' directory.

    .EXAMPLE
        Get-MediaStreamCollection 'movie.mkv' | Export-MediaStreamCollection -OutputDirectory '.\subtitles' -Type Subtitle -Language 'eng'
        # Exports only English subtitle streams from the collection.

    .EXAMPLE
        $collection = Get-MediaStreamCollection '*.mp4'
        Export-MediaStreamCollection -Collection $collection -OutputDirectory '.\extracted' -Force
        # Exports all streams from all MP4 files, overwriting existing files.

    .OUTPUTS
        None. Creates files in the specified OutputDirectory.

    .NOTES
        This function requires ffmpeg to be installed and available in the system PATH.
        
        The function uses the MediaStreamInfo.Export() method to extract individual streams.
        Each extracted stream maintains its original codec and quality.
        
        Output filenames follow the pattern: {original_filename}_{stream_type}_{type_index}_{language}.{extension}
        
        If the OutputDirectory doesn't exist, it will be created automatically.
        
        Use -Verbose to see detailed information about the extraction process.

    .LINK
        Get-MediaStreamCollection
        Export-MediaStream
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [MediaStreamInfoCollection]$Collection,
        [Parameter(Mandatory)]
        [string]$OutputDirectory,
        [Parameter()]
        [ValidateSet('Audio','Subtitle','Video','Data')]
        [string]$Type,
        [Parameter()]
        [string]$Language,
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        @(
            'Export-MediaStream'
        ) | Set-PreferenceInheritance
    }
    
    process {
        # Convert Type parameter to lowercase for the class method
        $typeFilter = $Type?.ToLowerInvariant()
        
        # Use the collection's ExportAllStreams method
        $Collection.ExportAllStreams($OutputDirectory, $Language, $typeFilter, $Force)
    }
} 