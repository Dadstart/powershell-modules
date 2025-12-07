function Get-FilteredVideoFiles {
    <#
    .SYNOPSIS
        Filters video files based on size and pattern criteria.
    .DESCRIPTION
        Processes directories to find video files that meet the specified criteria:
        - File size above minimum threshold
        - File name matches specified patterns
        - Provides detailed feedback about accepted and excluded files
        This function extracts the file filtering logic from Invoke-VideoCopy
        to improve maintainability and testability.
        Supports pipeline input for Path parameter.
    .PARAMETER Path
        Source directories containing video files to process.
        Supports wildcards and multiple directory paths.
        Can be piped from Get-ChildItem or similar commands.
    .PARAMETER FilePatterns
        Array of file patterns to match for processing.
    .PARAMETER MinimumFileSize
        Minimum file size in bytes for files to be considered valid.
        Default is 100MB.
    .EXAMPLE
        $files = Get-FilteredVideoFiles -Path "C:\Source" -FilePatterns "*.mkv" -MinimumFileSize 100MB
        Returns all .mkv files larger than 100MB from C:\Source.
    .EXAMPLE
        $files = Get-FilteredVideoFiles -Path "D:\Rips\*" -FilePatterns "C4_*","B3_*" -MinimumFileSize 2GB
        Returns all files matching DVD/Blu-ray patterns larger than 2GB from multiple directories.
    .EXAMPLE
        Get-ChildItem -Directory | Get-FilteredVideoFiles -FilePatterns "*.mkv" -MinimumFileSize 100MB
        Processes all directories from Get-ChildItem and returns filtered video files.
    .EXAMPLE
        "C:\Videos", "D:\Movies" | Get-FilteredVideoFiles -FilePatterns "*.mp4", "*.mkv"
        Processes multiple directories piped as strings and returns filtered video files.
    .OUTPUTS
        [System.IO.FileInfo[]] Array of file objects that meet the filtering criteria.
        Returns empty array if no files meet criteria or error occurs.
    .NOTES
        This function requires the Video module to be installed and available.
        Files are filtered by size and pattern matching.
        Provides detailed verbose output about filtering decisions.
        Supports pipeline input for flexible directory processing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FilePatterns,
        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [long]$MinimumFileSize = $Script:DefaultMinimumFileSize
    )
    begin {
        $allDirectories = @()
        Write-Message 'Initializing file filtering' -Type Verbose
        Write-Message "File patterns: $($FilePatterns -join ', ')" -Type Verbose
        Write-Message "Minimum file size: $MinimumFileSize" -Type Verbose
    }
    process {
        if ($Path) {
            $allDirectories += $Path
        }
    }
    end {
        return Invoke-WithErrorHandling -OperationName 'File Filtering' -DefaultReturnValue @() -ErrorEmoji '🎬' -ScriptBlock {
            Write-Message "Processing directories: $($allDirectories -join ', ')" -Type Info
            # Resolve all directories to absolute paths
            $directories = @()
            Get-Item -Path $allDirectories | ForEach-Object {
                if ($_.PSIsContainer) {
                    $directories += $_.FullName
                }
            }
            Write-Message "Found $($directories.Count) total directories to process" -Type Success
            # Check if we have any valid directories
            if ($directories.Count -eq 0) {
                Write-Message '🚫 No valid directories found. Exiting.' -Type Error
                return @()
            }
            $allAcceptedFiles = @()
            # Start progress tracking for directory processing
            $directoryProgress = Start-ProgressActivity -Activity 'Directory Processing' -Status 'Processing directories...' -TotalItems $directories.Count
            $directoryIndex = 0
            # Process each directory to find and filter video files
            foreach ($directory in $directories) {
                $directoryIndex++
                $directoryProgress.Update(@{
                        CurrentItem = $directoryIndex
                        Status      = "Processing directory: $([System.IO.Path]::GetFileName($directory))"
                    })
                Write-Message "📂 Processing directory: $directory" -Type Verbose
                # Process files in pattern order - files matching earlier patterns come first
                $accepted = @()
                $excluded = @()
                $processedFiles = @{}  # Track files already processed to avoid duplicates
                # Process each pattern in order
                foreach ($pattern in $FilePatterns) {
                    $files = Get-ChildItem -Path $directory -Filter $pattern -File
                    Write-Message "Pattern '$pattern' matched $($files.Count) files" -Type Debug
                    foreach ($file in $files) {
                        # Skip if already processed (matches earlier pattern)
                        if ($processedFiles.ContainsKey($file.FullName)) {
                            continue
                        }
                        $processedFiles[$file.FullName] = $true
                        # Check if file meets criteria: large size
                        $isLargeFile = $file.Length -gt $MinimumFileSize
                        if ($isLargeFile) {
                            $accepted += $file
                        }
                        else {
                            $excluded += $file
                        }
                    }
                }
                # Log and display exclusions
                foreach ($ex in $excluded) {
                    $sizeGB = [math]::Round($ex.Length / 1GB, 2)
                    Write-Message "⏭️ Excluded: $($ex.Name) (Size: ${sizeGB}GB)" -Type Verbose
                }
                Write-Message "✅ Accepted: $($accepted.Count) files from $directory" -Type Verbose
                $allAcceptedFiles += $accepted
            }
            $directoryProgress.Stop(@{ Status = 'Directory processing completed' })
            Write-Message "🎯 Total accepted files: $($allAcceptedFiles.Count)" -Type Verbose
            return $allAcceptedFiles
        }
    }
}
