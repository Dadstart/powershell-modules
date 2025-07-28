[CmdletBinding()]
param()

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message "Demonstrating AudioStreamConfig.ToFfmpegArgs method" -Type Info

# Example 1: Basic encoding configuration
Write-Message "Example 1: Basic encoding configuration" -Type Processing
$encodeConfig = [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1')
Write-Message "Configuration: $encodeConfig" -Type Info

$args = $encodeConfig.ToFfmpegArgs(0)
Write-Message "Generated FFmpeg arguments:" -Type Info
Write-Message "  $($args -join ' ')" -Type Info

# Example 2: Copy configuration
Write-Message "`nExample 2: Copy configuration" -Type Processing
$copyConfig = [AudioStreamConfig]::new(0, 'DTS-HD')
Write-Message "Configuration: $copyConfig" -Type Info

$args = $copyConfig.ToFfmpegArgs(0)
Write-Message "Generated FFmpeg arguments:" -Type Info
Write-Message "  $($args -join ' ')" -Type Info

# Example 3: Multiple audio streams
Write-Message "`nExample 3: Multiple audio streams" -Type Processing
$audioConfigs = @(
    [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1'),
    [AudioStreamConfig]::new(0, 'DTS-HD'),
    [AudioStreamConfig]::new(2, 'mp3', '192k', 2, 'Stereo Commentary')
)

Write-Message "Audio configurations:" -Type Info
foreach ($config in $audioConfigs) {
    Write-Message "  $config" -Type Info
}

Write-Message "Generated FFmpeg arguments for each stream:" -Type Info
for ($i = 0; $i -lt $audioConfigs.Count; $i++) {
    $args = $audioConfigs[$i].ToFfmpegArgs($i)
    Write-Message "  Stream $i`: $($args -join ' ')" -Type Info
}

# Example 4: Integration with Convert-VideoFile
Write-Message "`nExample 4: Integration with Convert-VideoFile" -Type Processing
Write-Message "Before ToFfmpegArgs (manual construction):" -Type Info
Write-Message "  # Manual FFmpeg argument construction" -Type Info
Write-Message "  for (`$i = 0; `$i -lt `$AudioStreams.Count; `$i++) {" -Type Info
Write-Message "      `$audioConfig = `$AudioStreams[`$i]" -Type Info
Write-Message "      `$pass2Args += '-map', `"0:a:`$(`$audioConfig.InputStreamIndex)`"" -Type Info
Write-Message "      if (`$audioConfig.Copy) {" -Type Info
Write-Message "          `$pass2Args += `"-c:a:`$i`", 'copy'" -Type Info
Write-Message "      } else {" -Type Info
Write-Message "          `$pass2Args += `"-c:a:`$i`", `$audioConfig.Codec" -Type Info
Write-Message "          if (`$audioConfig.Bitrate) {" -Type Info
Write-Message "              `$pass2Args += `"-b:a:`$i`", `$audioConfig.Bitrate" -Type Info
Write-Message "          }" -Type Info
Write-Message "          if (`$audioConfig.Channels) {" -Type Info
Write-Message "              `$pass2Args += `"-ac:a:`$i`", `$audioConfig.Channels.ToString()" -Type Info
Write-Message "          }" -Type Info
Write-Message "      }" -Type Info
Write-Message "      `$pass2Args += `"-metadata:s:a:`$i`", `"title=`"`$(`$audioConfig.Title)`"`"" -Type Info
Write-Message "  }" -Type Info

Write-Message "`nAfter ToFfmpegArgs (simplified):" -Type Info
Write-Message "  # Simplified FFmpeg argument construction" -Type Info
Write-Message "  for (`$i = 0; `$i -lt `$AudioStreams.Count; `$i++) {" -Type Info
Write-Message "      `$audioConfig = `$AudioStreams[`$i]" -Type Info
Write-Message "      `$pass2Args += `$audioConfig.ToFfmpegArgs(`$i)" -Type Info
Write-Message "  }" -Type Info

# Example 5: Different codecs and settings
Write-Message "`nExample 5: Different codecs and settings" -Type Processing
$codecExamples = @(
    [AudioStreamConfig]::new(0, 'aac', '256k', 2, 'Stereo AAC'),
    [AudioStreamConfig]::new(1, 'mp3', '192k', 2, 'Stereo MP3'),
    [AudioStreamConfig]::new(2, 'ac3', '384k', 6, 'Dolby Digital 5.1'),
    [AudioStreamConfig]::new(3, 'DTS-HD')  # Copy
)

Write-Message "Different codec configurations:" -Type Info
for ($i = 0; $i -lt $codecExamples.Count; $i++) {
    $config = $codecExamples[$i]
    $args = $config.ToFfmpegArgs($i)
    Write-Message "  $config" -Type Info
    Write-Message "    Args: $($args -join ' ')" -Type Info
}

# Example 6: Edge cases
Write-Message "`nExample 6: Edge cases" -Type Processing

# No bitrate specified
$noBitrateConfig = [AudioStreamConfig]::new(4, 'aac', $null, 2, 'Stereo No Bitrate')
Write-Message "No bitrate config: $noBitrateConfig" -Type Info
$args = $noBitrateConfig.ToFfmpegArgs(4)
Write-Message "  Args: $($args -join ' ')" -Type Info

# No channels specified
$noChannelsConfig = [AudioStreamConfig]::new(5, 'mp3', '128k', $null, 'Mono No Channels')
Write-Message "No channels config: $noChannelsConfig" -Type Info
$args = $noChannelsConfig.ToFfmpegArgs(5)
Write-Message "  Args: $($args -join ' ')" -Type Info

Write-Message "`nToFfmpegArgs method successfully demonstrates modular FFmpeg argument generation!" -Type Success 