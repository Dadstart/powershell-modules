[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Processing MKV files in current directory" -Type Info

# Set up video and audio configurations
$videoConfig = New-VideoEncodingConfig -Bitrate '5000k' -Preset 'slow'
$audioConfigs = @(
    (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
    (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy)
)

Write-Message "Video configuration: $videoConfig" -Type Info
Write-Message "Audio configurations:" -Type Info
foreach ($audioConfig in $audioConfigs) {
    Write-Message "  $audioConfig" -Type Info
}

# Get current directory and create MP4 folder if it doesn't exist
$currentDir = Get-Location
$mp4Folder = Join-Path $currentDir "MP4"
if (-not (Test-Path $mp4Folder)) {
    New-Item -ItemType Directory -Path $mp4Folder -Force | Out-Null
    Write-Message "Created MP4 folder: $mp4Folder" -Type Info
}

# Get all MKV files in the current directory
$mkvFiles = Get-ChildItem -Path $currentDir -Filter "*.mkv" -File
Write-Message "Found $($mkvFiles.Count) MKV files to process" -Type Info

if ($mkvFiles.Count -eq 0) {
    Write-Message "No MKV files found in current directory" -Type Warning
    return
}

# Process each MKV file
foreach ($mkvFile in $mkvFiles) {
    $outputFileName = [System.IO.Path]::ChangeExtension($mkvFile.Name, ".mp4")
    $outputPath = Join-Path $mp4Folder $outputFileName
    
    # Check if output file already exists
    if (Test-Path $outputPath) {
        Write-Message "Skipping $($mkvFile.Name) - output file already exists: $outputFileName" -Type Info
        continue
    }
    
    Write-Message "Processing $($mkvFile.Name) -> $outputFileName" -Type Processing
    
    try {
        Convert-VideoFile -InputFile $mkvFile.FullName -OutputFile $outputPath -VideoEncoding $videoConfig -AudioStreams $audioConfigs -Verbose
        Write-Message "Successfully converted $($mkvFile.Name) to $outputFileName" -Type Success
    }
    catch {
        Write-Message "Failed to convert $($mkvFile.Name): $($_.Exception.Message)" -Type Error
    }
}

Write-Message "Completed processing all MKV files" -Type Success
