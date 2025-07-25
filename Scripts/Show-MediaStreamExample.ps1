# Example script demonstrating Show-MediaStream and Format-MediaStream functions
# This script shows different ways to output tracks of different types

cls
Remove-Module NewMediaTools,MediaTools -Force
Import-Module C:\modules\modules\NewMedia\NewMediaTools.psd1 -Force

# Import the NewMedia module
Import-Module "$PSScriptRoot\Modules\NewMedia\NewMedia.psd1" -Force

$path = 'C:\temp\06\s06e01.raw.mkv'

# Example 1: Basic usage - show all tracks
Write-Message "=== Example 1: Show all tracks ===" -Type Info
Get-MediaStream -Path $path | Show-MediaStream

# Example 2: Show only video tracks with full detail
Write-Message "=== Example 2: Video tracks with full detail ===" -Type Info
Get-MediaStream -Path $path -TrackType Video | Show-MediaStream -DetailLevel Full

# Example 3: Show only audio tracks with basic info
Write-Message "=== Example 3: Audio tracks with basic info ===" -Type Info
Get-MediaStream -Path $path -TrackType Audio | Show-MediaStream -DetailLevel Basic

# Example 4: Format tracks for programmatic use
Write-Message "=== Example 4: Format tracks for programmatic use ===" -Type Info
$formattedTracks = Get-MediaStream -Path $path | Format-MediaStream
$formattedTracks | Format-Table -AutoSize

# Example 5: Export to CSV
Write-Message "=== Example 5: Export to CSV ===" -Type Info
Get-MediaStream -Path $path |
    Format-MediaStream -DetailLevel Detailed |
    Export-Csv -Path "media_tracks.csv" -NoTypeInformation

# Example 6: Filter and format specific track types
Write-Message "=== Example 6: Filter and format specific track types ===" -Type Info
$videoTracks = Get-MediaStream -Path $path -TrackType Video | Format-MediaStream
$audioTracks = Get-MediaStream -Path $path -TrackType Audio | Format-MediaStream

Write-Message "Video Tracks:" -Type Info
$videoTracks | Format-Table Index, Codec, Resolution, FrameRate, Bitrate -AutoSize

Write-Message "Audio Tracks:" -Type Info
$audioTracks | Format-Table Index, Codec, SampleRate, Channels, ChannelLayout, Bitrate -AutoSize

# Example 7: Advanced filtering and analysis
Write-Message "=== Example 7: Advanced filtering and analysis ===" -Type Info
$allTracks = Get-MediaStream -Path $path | Format-MediaStream

# Find high bitrate video tracks
$highBitrateVideo = $allTracks | Where-Object { $_.Type -eq 'video' -and $_.Bitrate -gt 10000000 }
Write-Message "High bitrate video tracks (>10 Mbps):" -Type Info
$highBitrateVideo | Format-Table Index, Codec, Resolution, Bitrate -AutoSize

# Find 5.1 audio tracks
$surroundAudio = $allTracks | Where-Object { $_.Type -eq 'audio' -and $_.ChannelLayout -eq '5.1' }
Write-Message "5.1 surround audio tracks:" -Type Info
$surroundAudio | Format-Table Index, Codec, SampleRate, ChannelLayout, Bitrate -AutoSize

# Example 8: JSON export with full detail
Write-Message "=== Example 8: JSON export with full detail ===" -Type Info
Get-MediaStream -Path $path |
    Format-MediaStream -DetailLevel Full |
    ConvertTo-Json -Depth 10 |
    Out-File "media_tracks_full.json" -Encoding UTF8

Write-Message "Examples completed. Check the generated files for detailed output." -Type Success
