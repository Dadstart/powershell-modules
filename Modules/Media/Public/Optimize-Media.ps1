function Optimize-Media {
    <#
    .SYNOPSIS
        Optimizes media files for size and quality.
    
    .DESCRIPTION
        Optimizes media files by reducing file size while maintaining acceptable quality.
        Supports different optimization strategies for video, audio, and image files.
    
    .PARAMETER Path
        The path to the media file or directory containing media files.
    
    .PARAMETER Recurse
        If specified, processes media files recursively in subdirectories.
    
    .PARAMETER Strategy
        The optimization strategy to use. Valid values are 'Size', 'Quality', 'Balanced'.
        Default is 'Balanced'.
    
    .PARAMETER OutputPath
        The output path for optimized files. If not specified, will overwrite original files.
    
    .PARAMETER Backup
        If specified, creates a backup of the original file before optimization.
    
    .EXAMPLE
        Optimize-Media -Path "C:\Videos\large_video.mp4" -Strategy Size
        
        Optimizes the video file for smaller size.
    
    .EXAMPLE
        Optimize-Media -Path "C:\Images" -Recurse -Strategy Quality -Backup
        
        Optimizes all images in the directory for better quality, creating backups.
    
    .OUTPUTS
        [MediaFile] Objects containing information about optimized media files.
    #>
    [CmdletBinding()]
    [OutputType([MediaFile])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [ValidateSet('Size', 'Quality', 'Balanced')]
        [string]$Strategy = 'Balanced',
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [switch]$Backup
    )
    
    try {
        # Validate and normalize the path
        $NormalizedPath = Get-Path -Path $Path -MustExist
        
        # Get media files
        $MediaFiles = Get-MediaInfo -Path $NormalizedPath -Recurse:$Recurse
        
        $OptimizedFiles = @()
        
        foreach ($MediaFile in $MediaFiles) {
            Write-Message -Message "Optimizing $($MediaFile.Name) using $Strategy strategy" -Level Info
            
            # Create backup if requested
            if ($Backup) {
                $BackupPath = $MediaFile.Path + '.backup'
                Copy-Item -Path $MediaFile.Path -Destination $BackupPath -Force
                Write-Message -Message "Created backup: $BackupPath" -Level Verbose
            }
            
            # Determine output path
            $TargetPath = if ($OutputPath) { $OutputPath } else { $MediaFile.Path }
            
            # Optimize based on media type
            $OptimizedFile = switch ($MediaFile.MediaType) {
                'Video' {
                    Optimize-VideoFile -InputPath $MediaFile.Path -OutputPath $TargetPath -Strategy $Strategy
                }
                'Audio' {
                    Optimize-AudioFile -InputPath $MediaFile.Path -OutputPath $TargetPath -Strategy $Strategy
                }
                'Image' {
                    Optimize-ImageFile -InputPath $MediaFile.Path -OutputPath $TargetPath -Strategy $Strategy
                }
                default {
                    Write-Message -Message "Skipping unsupported media type: $($MediaFile.MediaType)" -Level Warning
                    continue
                }
            }
            
            if ($OptimizedFile) {
                $OptimizedFiles += [MediaFile]::new($TargetPath)
                Write-Message -Message "Optimization completed for $($MediaFile.Name)" -Level Success
            }
        }
        
        return $OptimizedFiles
    }
    catch {
        Write-Message -Message "Error during optimization: $_" -Level Error
        throw
    }
} 