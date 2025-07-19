function Invoke-SafeFileRename {
    [CmdletBinding(SupportsShouldProcess)]
    <#
    .SYNOPSIS
        Safely renames files using temporary files to avoid conflicts.
    .DESCRIPTION
        This function takes a hashtable of file rename mappings and safely renames
        the corresponding files found in the specified directories. It uses temporary files
        to avoid overwriting existing files and handles complex rename scenarios where
        files may be both sources and targets. Can process multiple directories via pipeline.
    .PARAMETER Directory
        Directory containing the files to be renamed. Can be piped from Get-ChildItem or similar.
    .PARAMETER FileMappings
        Hashtable where keys are partial filenames to find and values are target names.
    .EXAMPLE
        Invoke-SafeFileRename -Directory "C:\Videos" -FileMappings @{"movie1" = "newmovie1"; "movie2" = "newmovie2"}
        Renames files containing "movie1" to "newmovie1" and "movie2" to "newmovie2" in C:\Videos.
    .EXAMPLE
        Get-ChildItem -Directory | Invoke-SafeFileRename -FileMappings @{"old" = "new"} -WhatIf
        Shows what would be renamed in all subdirectories without actually performing the operation.
    .EXAMPLE
        "C:\Videos", "C:\Music" | Invoke-SafeFileRename -FileMappings @{"document1" = "renamed_doc"; "image1" = "renamed_img"}
        Renames files in both C:\Videos and C:\Music directories.
    .EXAMPLE
        Invoke-SafeFileRename -Directory "C:\Media" -FileMappings @{"video1" = "video1.mkv"; "audio1" = "audio1.flac"}
        Change file extensions during rename.
    .INPUTS
        [string] - Directory path(s) to process
        [hashtable] - Hashtable of file rename mappings
    .OUTPUTS
        None. Performs file rename operations.
    .NOTES
        This function uses temporary files to ensure no data loss during complex rename operations.
        Any remaining temporary files after completion indicate an error occurred.
    #>
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Directory,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]$FileMappings
    )
    begin {
        Write-Message 'Initializing SafeFileRename for multiple directories' -Type Verbose
        Write-Message "File mappings: $($FileMappings | ConvertTo-Json -Compress)" -Type Verbose
        $processedDirectories = 0
        $totalFilesProcessed = 0
    }
    process {
        try {
            Write-Message "`n📁 Processing directory: $Directory" -Type Verbose
            # Validate directory exists
            if (-not (Test-Path -Path $Directory -PathType Container)) {
                Write-Message "Directory '$Directory' does not exist or is not a directory." -Type Error
                return
            }
            Write-Message "Directory: $Directory" -Type Verbose
            # Validate FileMappings
            if ($FileMappings.Count -eq 0) {
                Write-Message 'FileMappings hashtable cannot be empty.' -Type Error
                return
            }
            # Get all files in the directory
            Write-Message 'Enumerating files in directory' -Type Verbose
            $allFiles = Get-ChildItem -Path $Directory -File | ForEach-Object { $_.Name }
            Write-Message "Found $($allFiles.Count) files in directory" -Type Verbose
            # Find full filenames for each input partial name
            $finalMappings = @()
            $unmatchedInputs = @()
            # Start progress tracking for file mapping phase
            $mappingProgress = Start-ProgressActivity -Activity 'File Mapping' -Status 'Analyzing file mappings...' -TotalItems $FileMappings.Count
            $mappingIndex = 0
            foreach ($mapping in $FileMappings.GetEnumerator()) {
                $mappingIndex++
                $inputPartial = $mapping.Key
                $outputPartial = $mapping.Value
                $mappingProgress.Update(@{
                        CurrentItem = $mappingIndex
                        Status      = "Processing mapping: $inputPartial -> $outputPartial"
                    })
                Write-Message "Processing mapping: $inputPartial -> $outputPartial" -Type Debug
                # Find files that contain the input partial name
                $matchingFiles = @($allFiles | Where-Object { $_ -like "*$inputPartial*" })
                if ($matchingFiles.Count -eq 0) {
                    $unmatchedInputs += $inputPartial
                    Write-Message "No files found matching partial name: $inputPartial" -Type Warning
                }
                elseif ($matchingFiles.Count -gt 1) {
                    Write-Message "Multiple files found matching '$inputPartial': $($matchingFiles -join ', '). Using first match: $($matchingFiles[0])" -Type Warning
                    $finalMapping = [PSCustomObject]@{
                        InputPartial  = $inputPartial
                        OutputPartial = $outputPartial
                        SourceFile    = $matchingFiles[0]
                        TargetFile    = $outputPartial
                        Index         = $index
                    }
                    Write-Message "Final mapping: $($finalMapping | ConvertTo-Json)" -Type Debug
                    $finalMappings += $finalMapping
                }
                else {
                    $finalMapping = [PSCustomObject]@{
                        InputPartial  = $inputPartial
                        OutputPartial = $outputPartial
                        SourceFile    = $matchingFiles[0]
                        TargetFile    = $outputPartial
                        Index         = $index
                    }
                    Write-Message "Final mapping: $($finalMapping | ConvertTo-Json)" -Type Debug
                    $finalMappings += $finalMapping
                }
                $index++
            }
            $mappingProgress.Stop(@{ Status = 'File mapping completed' })
            if ($unmatchedInputs.Count -gt 0) {
                Write-Message "The following input partial names had no matches: $($unmatchedInputs -join ', ')" -Type Warning
            }
            if ($finalMappings.Count -eq 0) {
                Write-Message "No files to rename found in $Directory." -Type Warning
                return
            }
            Write-Message 'File mappings to process:' -Type Verbose
            foreach ($mapping in $finalMappings) {
                Write-Message "  $($mapping.SourceFile) -> $($mapping.TargetFile)" -Type Verbose
            }
            # Determine final target filenames (with extensions preserved)
            Write-Message 'Determining final target filenames' -Type Debug
            for ($i = 0; $i -lt $finalMappings.Count; $i++) {
                $mapping = $finalMappings[$i]
                $sourceExtension = [System.IO.Path]::GetExtension($mapping.SourceFile)
                $outputExtension = [System.IO.Path]::GetExtension($mapping.OutputPartial)
                # Replace the matching substring in the original filename
                $sourceNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($mapping.SourceFile)
                $finalNameWithoutExt = $sourceNameWithoutExt -replace [regex]::Escape($mapping.InputPartial), $mapping.OutputPartial
                # Use output extension if provided, otherwise preserve source extension
                $finalExtension = if ($outputExtension) { $outputExtension } else { $sourceExtension }
                $finalName = $finalNameWithoutExt + $finalExtension
                $finalMappings[$i].TargetFile = $finalName
                Write-Message "Final target: $($mapping.SourceFile) -> $finalName" -Type Debug
            }
            # Check for conflicts and create rename plan
            Write-Message 'Checking for conflicts and creating rename plan' -Type Debug
            $renamePlans = @()
            $temporaryFiles = @()
            $tempCounter = 0
            # Start progress tracking for conflict resolution phase
            $conflictProgress = Start-ProgressActivity -Activity 'Conflict Resolution' -Status 'Analyzing file conflicts...' -TotalItems $finalMappings.Count
            $conflictIndex = 0
            # First pass: identify conflicts and create temporary names
            foreach ($mapping in $finalMappings) {
                $conflictIndex++
                $conflictProgress.Update(@{
                        CurrentItem = $conflictIndex
                        Status      = "Checking conflicts for: $($mapping.SourceFile)"
                    })
                $sourcePath = Get-Path -Path $Directory, $mapping.SourceFile -PathType Absolute -ValidatePath File
                $targetPath = Get-Path -Path $Directory, $mapping.TargetFile -PathType Absolute
                # Check if target already exists
                if (Test-Path -Path $targetPath) {
                    # Create temporary name for existing target
                    do {
                        $tempCounter++
                        $tempName = "TEMP_RENAME_$tempCounter" + [System.IO.Path]::GetExtension($mapping.TargetFile)
                        $tempPath = Get-Path -Path $Directory, $tempName -PathType Absolute
                    } while (Test-Path -Path $tempPath)
                    $temporaryFiles += [PSCustomObject]@{
                        OriginalFile     = $mapping.TargetFile
                        TemporaryFile    = $tempName
                        TemporaryPath    = $tempPath
                        IsTargetConflict = $true
                    }
                    Write-Message "Target conflict detected: $($mapping.TargetFile) -> temporary: $tempPath" -Type Warning
                }
                # Check if source needs temporary name (if it's also a target)
                $isSourceAlsoTarget = $finalMappings | Where-Object { $_.TargetFile -eq $mapping.SourceFile }
                if ($isSourceAlsoTarget) {
                    do {
                        $tempCounter++
                        $tempName = "TEMP_RENAME_$tempCounter" + [System.IO.Path]::GetExtension($mapping.SourceFile)
                        $tempPath = Get-Path -Path $Directory, $tempName -PathType Absolute
                    } while (Test-Path -Path $tempPath)
                    $temporaryFile = [PSCustomObject]@{
                        OriginalFile     = $mapping.SourceFile
                        TemporaryFile    = $tempName
                        TemporaryPath    = $tempPath
                        IsTargetConflict = $false
                    }
                    Write-Message "OriginalFile: $($temporaryFile.OriginalFile)" -Type Debug
                    Write-Message "TemporaryFile: $($temporaryFile.TemporaryFile)" -Type Debug
                    Write-Message "TemporaryPath: $($temporaryFile.TemporaryPath)" -Type Debug
                    Write-Message "IsTargetConflict: $($temporaryFile.IsTargetConflict)" -Type Debug
                    $temporaryFiles += $temporaryFile
                    Write-Message "Source is also target: $($mapping.SourceFile) -> temporary: $tempName" -Type Verbose
                }
            }
            $conflictProgress.Stop(@{ Status = 'Conflict analysis completed' })
            # Second pass: create the actual rename plan
            foreach ($mapping in $finalMappings) {
                $sourcePath = Get-Path -Path $Directory, $mapping.SourceFile -PathType Absolute -ValidatePath File
                $targetPath = Get-Path -Path $Directory, $mapping.TargetFile -PathType Absolute
                # Find if source has a temporary name
                $sourceTemp = $temporaryFiles | Where-Object { $_.OriginalFile -eq $mapping.SourceFile -and -not $_.IsTargetConflict }
                $actualSourceFile = if ($sourceTemp) { $sourceTemp.TemporaryFile } else { $mapping.SourceFile }
                $actualSourcePath = Get-Path -Path $Directory, $actualSourceFile -PathType Absolute
                # Find if target has a temporary name
                $targetTemp = $temporaryFiles | Where-Object { $_.OriginalFile -eq $mapping.TargetFile -and $_.IsTargetConflict }
                $actualTargetFile = if ($targetTemp) { $targetTemp.TemporaryFile } else { $mapping.TargetFile }
                $actualTargetPath = Get-Path -Path $Directory, $actualTargetFile -PathType Absolute
                $renamePlan = [PSCustomObject]@{
                    SourceFile       = $mapping.SourceFile
                    TargetFile       = $mapping.TargetFile
                    ActualSourceFile = $actualSourceFile
                    ActualTargetFile = $actualTargetFile
                    SourcePath       = $actualSourcePath
                    TargetPath       = $actualTargetPath
                    Operation        = 'Rename'
                }
                Write-Message "Rename plan: $($renamePlan | ConvertTo-Json)" -Type Debug
                # Display the plan
                Write-Message "Rename plan for $Directory`:" -Type Verbose
                Write-Message "  $($renamePlan.SourceFile) ➡️ $($renamePlan.TargetFile)" -Type Verbose
                if ($renamePlan.ActualSourceFile -ne $renamePlan.SourceFile) {
                    Write-Message "    (via temporary: $($renamePlan.ActualSourceFile))" -Type Verbose
                }
                if ($renamePlan.ActualTargetFile -ne $renamePlan.TargetFile) {
                    Write-Message "    (target was: $($renamePlan.ActualTargetFile))" -Type Verbose
                }
                $renamePlans += $renamePlan
            }
            if ($temporaryFiles.Count -gt 0) {
                Write-Message 'Temporary files to be created' -Type Verbose
                foreach ($temp in $temporaryFiles) {
                    Write-Message "OriginalFile: $($temp.OriginalFile)" -Type Debug
                    Write-Message "TemporaryFile: $($temp.TemporaryFile)" -Type Debug
                }
            }
            # Execute the rename plan using ShouldProcess
            if ($PSCmdlet.ShouldProcess("$($finalMappings.Count) files in $Directory", 'Rename')) {
                Write-Message "Executing rename operations in $Directory..." -Type Verbose
                # Start progress tracking for rename execution
                $totalOperations = $temporaryFiles.Count + $renamePlans.Count + $temporaryFiles.Count
                $renameProgress = Start-ProgressActivity -Activity 'File Rename Operations' -Status 'Starting rename operations...' -TotalItems $totalOperations
                $operationCount = 0
                # Step 1: Create temporary files for conflicts
                Write-Message "Creating $($temporaryFiles.Count) temporary files for conflicts" -Type Debug
                foreach ($temp in $temporaryFiles) {
                    $operationCount++
                    $renameProgress.Update(@{
                            CurrentItem = $operationCount
                            Status      = "Creating temporary: $($temp.OriginalFile) -> $($temp.TemporaryFile)"
                        })
                    $originalPath = Get-Path -Path $Directory, $temp.OriginalFile -PathType Absolute
                    Write-Message "Creating temporary file: $($temp.OriginalFile) -> $($temp.TemporaryFile)" -Type Verbose
                    Write-Message "Path: $originalPath; Destination: $($temp)" -Type Debug
                    Move-Item -Path $originalPath -Destination $temp.TemporaryPath
                }
                # Step 2: Perform the actual renames
                Write-Message "Performing $($renamePlans.Count) actual renames" -Type Debug
                foreach ($operation in $renamePlans) {
                    $operationCount++
                    $renameProgress.Update(@{
                            CurrentItem = $operationCount
                            Status      = "Renaming: $($operation.ActualSourceFile) -> $($operation.TargetFile)"
                        })
                    Write-Message "Renaming: $($operation.ActualSourceFile) -> $($operation.TargetFile)" -Type Verbose
                    Move-Item -Path $operation.SourcePath -Destination $operation.TargetPath
                }
                # Step 3: Clean up temporary files (rename them to their final names)
                Write-Message "Deleting $($temporaryFiles.Count) temporary files" -Type Debug
                foreach ($temp in $temporaryFiles) {
                    $operationCount++
                    $renameProgress.Update(@{
                            CurrentItem = $operationCount
                            Status      = "Cleaning up temporary: $($temp.TemporaryFile)"
                        })
                    if ($temp.IsTargetConflict) {
                        # This was a target conflict, rename temp to final target
                        $finalTarget = $FileMappings | Where-Object { $_.TargetFile -eq $temp.OriginalFile }
                        if ($finalTarget) {
                            $finalTargetPath = Get-Path -Path $Directory, $finalTarget.TargetFile -PathType Absolute
                            Write-Message "Finalizing temporary file: $($temp.TemporaryFile) -> $($finalTarget.TargetFile)" -Type Verbose
                            Move-Item -Path $temp.TemporaryPath -Destination $finalTargetPath
                        }
                    }
                }
                $renameProgress.Stop(@{ Status = 'All rename operations completed successfully' })
                Write-Message "All rename operations completed successfully in $Directory." -Type Verbose
                # Verify no temporary files remain
                $remainingTempFiles = Get-ChildItem -Path $Directory -Filter 'TEMP_RENAME_*' -File
                if ($remainingTempFiles.Count -gt 0) {
                    Write-Message "ERROR: Temporary files remain after operations in $($Directory): $($remainingTempFiles.Name -join ', ')" -Type Error
                    Write-Message 'This indicates an error occurred during the rename process.' -Type Error
                    Write-Message 'Please manually resolve these temporary files.' -Type Error
                }
                $processedDirectories++
                $totalFilesProcessed += $finalMappings.Count
            }
        }
        catch {
            Write-Message "Error during rename operations in $($Directory): $($_.Exception.Message)" -Type Error
            Write-Message 'Some operations may have been completed. Please check the directory for temporary files.' -Type Error
        }
    }
    end {
        Write-Message "`n📊 === SafeFileRename Summary ===" -Type Verbose
        Write-Message "✅ Directories processed: $processedDirectories" -Type Verbose
        Write-Message "📁 Total files processed: $totalFilesProcessed" -Type Verbose
    }
} 
