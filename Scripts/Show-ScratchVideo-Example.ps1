[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message 'Demonstrating updated scratch-video.ps1 functionality' -Type Info

# Show the configuration that would be used
Write-Message 'Configuration used by scratch-video.ps1:' -Type Info
Write-Message "" -Type Info

Write-Message 'Video Configuration:' -Type Info
Write-Message "  `$videoConfig = New-VideoEncodingConfig -Bitrate '5000k' -Preset 'slow'" -Type Info
$videoConfig = New-VideoEncodingConfig -Bitrate '5000k' -Preset 'slow'
Write-Message "  Result: $videoConfig" -Type Info
Write-Message "" -Type Info

Write-Message 'Audio Configuration:' -Type Info
Write-Message "  `$audioConfigs = @(" -Type Info
Write-Message "      (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1')," -Type Info
Write-Message "      (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy)" -Type Info
Write-Message '  )' -Type Info

$audioConfigs = @(
    (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
    (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy)
)

Write-Message '  Results:' -Type Info
foreach ($audioConfig in $audioConfigs) {
    Write-Message "    $audioConfig" -Type Info
}
Write-Message '' -Type Info

# Show the processing logic
Write-Message 'Processing Logic:' -Type Info
Write-Message '1. Find all MKV files in current directory' -Type Info
Write-Message "2. Create MP4 folder if it doesn't exist" -Type Info
Write-Message '3. For each MKV file:' -Type Info
Write-Message '   - Generate output filename (same name, .mp4 extension)' -Type Info
Write-Message '   - Check if output already exists (skip if it does)' -Type Info
Write-Message '   - Convert using Convert-VideoFile with configurations' -Type Info
Write-Message "" -Type Info

# Show example FFmpeg command that would be generated
Write-Message 'Example FFmpeg command that would be generated:' -Type Info
Write-Message '  ffmpeg -y -i input.mkv -c:v libx264 -preset slow -b:v 5000k -pass 2 -passlogfile input.ffmpeg -map 0:v:0 -map 0:a:1 -c:a:0 aac -b:a:0 384k -ac:a:0 6 -metadata:s:a:0 title=\'Surround 5.1\" -map 0:a:0 -c:a:1 copy -metadata:s:a:1 title=\"DTS-HD\" -map_metadata 0 -map_chapters 0 -movflags +faststart output.mp4" -Type Info
Write-Message "" -Type Info

# Show usage instructions
Write-Message 'Usage:' -Type Info
Write-Message '1. Place MKV files in the current directory' -Type Info
Write-Message '2. Run: .\scratch-video.ps1' -Type Info
Write-Message '3. Converted MP4 files will be placed in the MP4 folder' -Type Info
Write-Message '4. Existing output files will be skipped' -Type Info
Write-Message '' -Type Info

Write-Message 'The script now uses the modular configuration approach with List[string] for efficient FFmpeg argument generation!' -Type Success
