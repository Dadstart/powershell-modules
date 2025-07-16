function Copy-FileWithMetadata {
    <#
    .SYNOPSIS
        Copies video files with TVDb metadata integration and episode-based renaming.
    .DESCRIPTION
        Handles the file copying and renaming phase of video processing by:
        - Copying video files to destination directory
        - Renaming files with TVDb metadata in filename
        - Matching files to episodes based on order
        - Providing detailed feedback about the copying process
        - Supporting WhatIf and Confirm operations
        This function extracts the file copying logic from Invoke-VideoCopy
        to improve maintainability and testability.
        Supports pipeline input for Files parameter.
    .PARAMETER Files
        Array of file objects to copy and rename.
        Can be piped from Get-ChildItem or similar commands.
    .PARAMETER Episodes
        Array of episode information objects from TVDb.
    .PARAMETER Destination
        Destination directory where copied files will be placed.
    .PARAMETER Title
        The title of the content being processed.
    .PARAMETER Season
        The season number for the content.
    .EXAMPLE
        $copiedFiles = Copy-FileWithMetadata -Files $files -Episodes $episodes -Destination "C:\Output" -Title "Breaking Bad" -Season 1
        Copies and renames Breaking Bad Season 1 files with TVDb metadata.
    .EXAMPLE
        Get-ChildItem "C:\Source\*.mkv" | Copy-FileWithMetadata -Episodes $episodes -Destination "C:\Output" -Title "The Office" -Season 3
        Processes all .mkv files from Get-ChildItem and copies them with metadata.
    .EXAMPLE
        $files | Copy-FileWithMetadata -Episodes $episodes -Destination "C:\Output" -Title "Game of Thrones" -Season 1
        Processes files piped as objects and copies them with metadata.
    .OUTPUTS
        [string[]] Array of destination file paths that were successfully copied.
        Returns empty array if no files were copied or error occurs.
    .NOTES
        This function requires the Video module to be installed and available.
        Files are renamed with TVDb metadata in the format:
        "{Title} {tvdb {Id}} - s{season}e{episode}.mkv"
        Supports WhatIf and Confirm operations for safe testing.
        Checks for existing files with same size to avoid duplicate copies.
        Supports pipeline input for flexible file processing.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.IO.FileInfo[]]$Files,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$Episodes,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        [Parameter(Mandatory)]
        [ValidateRange(1, 99)]
        [int]$Season
    )
    begin {
        $allFiles = @()
        Write-Message "Initializing file copying with metadata and pipeline support" -Type Verbose
        Write-Message "Destination: $Destination" -Type Verbose
        Write-Message "Title: $Title" -Type Verbose
        Write-Message "Season: $Season" -Type Verbose
        Write-Message "Episode count: $($Episodes.Count)" -Type Verbose
    }
    process {
        if ($Files) {
            $allFiles += $Files
        }
    }
    end {
        return Invoke-WithErrorHandling -OperationName "File copying with metadata" -DefaultReturnValue @() -ErrorEmoji "🎬" -ScriptBlock {
            # Check if we have enough files for all episodes
            if ($allFiles.Count -eq 0) {
                Write-Message '🚫 No files provided for copying.' -Type Error
                return @()
            }
            if ($allFiles.Count -lt $Episodes.Count) {
                Write-Message "⚠️ Found $($allFiles.Count) files but need $($Episodes.Count) episodes. Some episodes may be missing." -Type Warning
            }
            # Copy files with TVDb metadata
            Write-Message "🎬 Copying $($allFiles.Count) files to destination"
            $copiedFiles = @()
            for ($i = 0; $i -lt [Math]::Min($Episodes.Count, $allFiles.Count); $i++) {
                $episode = $Episodes[$i]
                $file = $allFiles[$i]
                # Create episode-based filename with TVDb metadata
                $episodeNumber = $episode.Number
                $episodeTitle = $episode.Name
                $tvdbId = $episode.Id
                # Clean episode title for filename
                $cleanTitle = $episodeTitle -replace '[<>:"/\\|?*]', ''
                $cleanTitle = $cleanTitle -replace '\s+', ' '
                $cleanTitle = $cleanTitle.Trim()
                # Create new filename with metadata
                $newFileName = "$Title {tvdb $tvdbId} - s{0:D2}e{1:D2} - $cleanTitle.mkv" -f $Season, $episodeNumber
                $destinationPath = Get-Path -Path $Destination, $newFileName -PathType Absolute
                Write-Message "📁 Copying: $($file.Name) -> $newFileName" -Type Verbose
                # Check if destination file already exists with same size
                if (Test-Path $destinationPath) {
                    $existingFile = Get-Item $destinationPath
                    if ($existingFile.Length -eq $file.Length) {
                        Write-Message "⏭️ Skipping: $newFileName (same size, likely already copied)" -Type Verbose
                        $copiedFiles += $destinationPath
                        continue
                    }
                    else {
                        Write-Message "⚠️ File exists but different size, will overwrite: $newFileName" -Type Warning
                    }
                }
                # Copy file with WhatIf/Confirm support
                $copyParams = @{
                    Path = $file.FullName
                    Destination = $destinationPath
                    Force = $true
                }
                if ($PSCmdlet.ShouldProcess($destinationPath, "Copy file")) {
                    Copy-Item @copyParams
                    if (Test-Path $destinationPath) {
                        Write-Message "✅ Copied: $newFileName" -Type Success
                        $copiedFiles += $destinationPath
                    }
                    else {
                        Write-Message "❌ Failed to copy: $newFileName" -Type Error
                    }
                }
                else {
                    # WhatIf mode - add to copied files for consistency
                    $copiedFiles += $destinationPath
                }
            }
            Write-Message "🎯 Total files copied: $($copiedFiles.Count)" -Type Verbose
            return $copiedFiles
        }
    }
} 
