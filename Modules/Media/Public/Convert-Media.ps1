function Convert-Media {
    <#
    .SYNOPSIS
        Converts media files between different formats.
    
    .DESCRIPTION
        Converts media files from one format to another using specified codecs and settings.
        Supports video, audio, and image conversion with customizable quality settings.
    
    .PARAMETER InputPath
        The path to the input media file.
    
    .PARAMETER OutputPath
        The path for the output file. If not specified, will use the same name with new extension.
    
    .PARAMETER Format
        The target format for conversion. Valid values depend on the input media type.
    
    .PARAMETER Quality
        The quality setting for conversion. Valid values are 'Low', 'Medium', 'High', 'Lossless'.
        Default is 'High'.
    
    .PARAMETER Codec
        The codec to use for conversion. If not specified, will use the best available codec.
    
    .PARAMETER PreserveMetadata
        If specified, preserves metadata from the original file.
    
    .EXAMPLE
        Convert-Media -InputPath "video.avi" -Format "mp4" -Quality High
        
        Converts an AVI video to MP4 with high quality settings.
    
    .EXAMPLE
        Convert-Media -InputPath "audio.wav" -OutputPath "output.mp3" -Quality Medium
        
        Converts a WAV audio file to MP3 with medium quality.
    
    .EXAMPLE
        Convert-Media -InputPath "image.jpg" -Format "png" -Quality Lossless
        
        Converts a JPG image to PNG with lossless quality.
    
    .OUTPUTS
        [MediaFile] The converted media file object.
    #>
    [CmdletBinding()]
    [OutputType([MediaFile])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$InputPath,
        
        [Parameter(Position = 1)]
        [string]$OutputPath,
        
        [Parameter(Mandatory)]
        [string]$Format,
        
        [Parameter()]
        [ValidateSet('Low', 'Medium', 'High', 'Lossless')]
        [string]$Quality = 'High',
        
        [Parameter()]
        [string]$Codec,
        
        [Parameter()]
        [switch]$PreserveMetadata
    )
    
    try {
        # Validate input path
        $NormalizedInputPath = Get-Path -Path $InputPath -PathType File -MustExist
        
        # Create MediaFile object for input
        $InputMedia = [MediaFile]::new($NormalizedInputPath)
        
        if (-not $InputMedia.IsValid()) {
            throw "Invalid media file: $InputPath"
        }
        
        Write-Message -Message "Converting $($InputMedia.Name) to $Format format" -Level Info
        
        # Determine output path if not specified
        if (-not $OutputPath) {
            $InputDirectory = Split-Path $NormalizedInputPath -Parent
            $InputName = [System.IO.Path]::GetFileNameWithoutExtension($NormalizedInputPath)
            $OutputPath = Join-Path $InputDirectory "$InputName.$Format"
        }
        
        # Normalize output path
        $NormalizedOutputPath = Get-Path -Path $OutputPath
        
        # Ensure output directory exists
        $OutputDirectory = Split-Path $NormalizedOutputPath -Parent
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Perform conversion based on media type
        switch ($InputMedia.MediaType) {
            'Video' {
                $Result = Convert-VideoFile -InputPath $NormalizedInputPath -OutputPath $NormalizedOutputPath -Format $Format -Quality $Quality -Codec $Codec -PreserveMetadata:$PreserveMetadata
            }
            'Audio' {
                $Result = Convert-AudioFile -InputPath $NormalizedInputPath -OutputPath $NormalizedOutputPath -Format $Format -Quality $Quality -Codec $Codec -PreserveMetadata:$PreserveMetadata
            }
            'Image' {
                $Result = Convert-ImageFile -InputPath $NormalizedInputPath -OutputPath $NormalizedOutputPath -Format $Format -Quality $Quality -PreserveMetadata:$PreserveMetadata
            }
            default {
                throw "Unsupported media type: $($InputMedia.MediaType)"
            }
        }
        
        if ($Result) {
            Write-Message -Message "Conversion completed successfully: $NormalizedOutputPath" -Level Success
            
            # Return the converted file as MediaFile object
            return [MediaFile]::new($NormalizedOutputPath)
        }
        else {
            throw "Conversion failed for $($InputMedia.Name)"
        }
    }
    catch {
        Write-Message -Message "Error during conversion: $_" -Level Error
        throw
    }
} 