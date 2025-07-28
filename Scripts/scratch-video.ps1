[CmdletBinding()]
param (
    [Parameter()]
    [string]$InputFile,
    [Parameter()]
    [string]$OutputFile
)

$InputFile = Get-Path $InputFile -PathType Absolute -ValidatePath File
$OutputFile = Get-Path $OutputFile -PathType Absolute

# $mediaFile = Get-MediaFile -Path $InputFile

# Convert the mediaFile/InputFile
Write-Message "Converting $InputFile to $OutputFile" -Type Processing

# video to libx264 preset slow, bitrate 5000k, 2-pass
# don't use VideoEncodingSettings or New-VideoEncodingSettings

# audio stream 2 is DTS Surround 5.1 and should become stream 1. It will should be encoded as aac 6 channel 384kbps named 'Surround 5.1'
# don't use New-AudioTrackMapping or New-AudioEncodingSettings

# audio stream 1 is DTS DTS-HD and should become stream 2. This stream should be a copy of the original stream, named 'DTS-HD'.
# don't use New-AudioTrackMapping or New-AudioEncodingSettings

# metadata and chapters from input
# don't use Convert-MediaFile

# 2-pass encoding with libx264 preset slow, 5000k bitrate
$passLogFile = [System.IO.Path]::ChangeExtension((Get-Path -Path $OutputFile -Pathtype Leaf), '.ffmpeg')

Write-Message 'Starting 2-pass encoding - Pass 1' -Type Processing
# Pass 1: Video only, no audio
$pass1Args = @(
    '-y',
    '-i', $InputFile,
    '-c:v', 'libx264',
    '-preset', 'slow',
    '-b:v', '5000k',
    '-pass', '1',
    '-passlogfile', $passLogFile,
    '-an',  # No audio
    '-sn',  # No subtitles
    '-f', 'null',
    'NUL'
)

$result = Invoke-FFMpeg -Arguments $pass1Args -Verbose
if ($result.ExitCode -ne 0) {
    Write-Message "Pass 1 failed: $($result.Error)" -Type Error
    throw "Pass 1 failed with exit code $($result.ExitCode)"
}

Write-Message 'Pass 1 completed successfully' -Type Success
Write-Message 'Starting 2-pass encoding - Pass 2' -Type Processing

# Pass 2: Full conversion with audio streams
$pass2Args = @(
    '-y',
    '-i', $InputFile,
    '-c:v', 'libx264',
    '-preset', 'slow',
    '-b:v', '5000k',
    '-pass', '2',
    '-passlogfile', $passLogFile,
    # Map video stream
    '-map', '0:v:0',
    # Audio stream 2 (DTS Surround 5.1) becomes first output stream, encoded as AAC 6-channel 384kbps
    '-map', '0:a:1',
    '-c:a:0', 'aac',
    '-b:a:0', '384k',
    '-ac:a:0', '6',
    '-metadata:s:a:0', 'title="Surround 5.1"',
    # Audio stream 1 (DTS-HD) becomes second output stream, copied as-is
    '-map', '0:a:0',
    '-c:a:1', 'copy',
    '-metadata:s:a:1', 'title="DTS-HD"',
    # Copy metadata and chapters from input
    '-map_metadata', '0',
    '-map_chapters', '0',
    # MP4 optimization
    '-movflags', '+faststart',
    '-y',  # Overwrite output
    $OutputFile
)

$result = Invoke-FFMpeg -Arguments $pass2Args -Verbose
if ($result.ExitCode -ne 0) {
    Write-Message "Pass 2 failed: $($result.Error)" -Type Error
    throw "Pass 2 failed with exit code $($result.ExitCode)"
}

Write-Message 'Pass 2 completed successfully' -Type Success

# Clean up pass log file
if (Test-Path $passLogFile) {
    Remove-Item $passLogFile -Force
    Write-Message 'Cleaned up pass log file' -Type Verbose
}

if (Test-Path $OutputFile) {
    Write-Message 'Conversion completed successfully' -Type Success
}
else {
    Write-Message 'Conversion failed' -Type Error
}
