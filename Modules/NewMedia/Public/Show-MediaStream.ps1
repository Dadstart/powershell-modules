function Show-MediaStream {
    <#
    .SYNOPSIS
        Displays media tracks with type-specific formatting and properties.
    .DESCRIPTION
        Show-MediaStream formats and displays media track information with properties
        specific to each track type (Video, Audio, Subtitle, Data). The function
        uses consistent formatting and color coding to present track information
        in a readable format.
        Video tracks show: Index, Codec, Profile, Resolution, Frame Rate, Bitrate, Duration
        Audio tracks show: Index, Codec, Profile, Sample Rate, Channels, Layout, Bitrate, Duration
        Subtitle tracks show: Index, Codec, Language, Title, Duration
        Data tracks show: Index, Codec, Title, Duration
    .PARAMETER Track
        The MediaStream object(s) to display. Can be a single track or an array of tracks.
    .PARAMETER DetailLevel
        The level of detail to include in the output. Valid values are 'Basic', 'Detailed', and 'Full'.
        Default is 'Detailed'.
    .PARAMETER TrackType
        Filter to show only specific track types. Valid values are 'Video', 'Audio', 'Subtitle', 'Data', 'All'.
        Default is 'All'.
    .EXAMPLE
        Get-MediaStream -Path "C:\video.mkv" | Show-MediaStream
        Displays all tracks from the video file with detailed formatting.
    .EXAMPLE
        Get-MediaStream -Path "C:\video.mkv" -TrackType Video | Show-MediaStream -DetailLevel Full
        Displays only video tracks with full detail including all raw properties.
    .EXAMPLE
        $tracks = Get-MediaStream -Path "C:\video.mkv"
        Show-MediaStream -Track $tracks -TrackType Audio -DetailLevel Basic
        Displays only audio tracks with basic information.
    .OUTPUTS
        None. This function writes formatted output to the console.
    .NOTES
        This function uses the Write-Message infrastructure for consistent formatting
        and color coding across the module.
    .LINK
        Get-MediaStream
        Write-Message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [MediaStream]$Track,
        [Parameter()]
        [ValidateSet('Basic', 'Detailed', 'Full')]
        [string]$DetailLevel = 'Detailed',
        [Parameter()]
        [ValidateSet('Video', 'Audio', 'Subtitle', 'Data', 'All')]
        [string]$TrackType = 'All'
    )
    begin {
        $allTracks = [System.Collections.ArrayList]::new()
        Write-Message "Initializing media track display with DetailLevel: $DetailLevel, TrackType: $TrackType" -Type Verbose
    }
    process {
        if ($TrackType -eq 'All' -or $Track.Type -eq $TrackType) {
            $null = $allTracks.Add($Track)
        }
    }
    end {
        if ($allTracks.Count -eq 0) {
            Write-Message "No tracks found matching the specified criteria" -Type Warning
            return
        }
        Write-Message "Displaying $($allTracks.Count) track(s)" -Type Info
        foreach ($track in $allTracks) {
            Show-SingleTrack -Track $track -DetailLevel $DetailLevel
        }
    }
}
function Show-SingleTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaStream]$Track,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    # Header with track type and index
    $typeColor = switch ($Track.Type) {
        'video' { 'Cyan' }
        'audio' { 'Green' }
        'subtitle' { 'Yellow' }
        'data' { 'Magenta' }
        default { 'White' }
    }
    Write-Message "=== $($Track.Type.ToUpper()) TRACK $($Track.Index) ===" -Type Info
    # Common properties for all track types
    Write-Message "Codec: $($Track.Codec)" -Type Info
    if ($Track.Title) {
        Write-Message "Title: $($Track.Title)" -Type Info
    }
    if ($Track.Language) {
        Write-Message "Language: $($Track.Language)" -Type Info
    }
    if ($Track.Duration -gt [TimeSpan]::Zero) {
        Write-Message "Duration: $($Track.Duration.ToString('hh\:mm\:ss'))" -Type Info
    }
    if ($Track.Bitrate -gt 0) {
        Write-Message "Bitrate: $([math]::Round($Track.Bitrate / 1000, 1)) kbps" -Type Info
    }
    # Type-specific properties
    switch ($Track.Type) {
        'video' {
            Show-VideoTrackProperties -Track $Track -DetailLevel $DetailLevel
        }
        'audio' {
            Show-AudioTrackProperties -Track $Track -DetailLevel $DetailLevel
        }
        'subtitle' {
            Show-SubtitleTrackProperties -Track $Track -DetailLevel $DetailLevel
        }
        'data' {
            Show-DataTrackProperties -Track $Track -DetailLevel $DetailLevel
        }
    }
    # Raw data for Full detail level
    if ($DetailLevel -eq 'Full') {
        Write-Message "Raw Data:" -Type Debug
        $Track.Raw | Format-List | Write-Message -Type Debug
    }
    Write-Message "" -Type Info
}
function Show-VideoTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaStream]$Track,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $raw = $Track.Raw
    # Basic video properties
    if ($raw.width -and $raw.height) {
        Write-Message "Resolution: $($raw.width)x$($raw.height)" -Type Info
    }
    if ($raw.profile) {
        Write-Message "Profile: $($raw.profile)" -Type Info
    }
    if ($raw.pix_fmt) {
        Write-Message "Pixel Format: $($raw.pix_fmt)" -Type Info
    }
    if ($raw.r_frame_rate -and $raw.r_frame_rate -ne '0/0') {
        Write-Message "Frame Rate: $($raw.r_frame_rate)" -Type Info
    }
    if ($raw.avg_frame_rate -and $raw.avg_frame_rate -ne '0/0') {
        Write-Message "Average Frame Rate: $($raw.avg_frame_rate)" -Type Info
    }
    if ($raw.display_aspect_ratio) {
        Write-Message "Aspect Ratio: $($raw.display_aspect_ratio)" -Type Info
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($raw.level) {
            Write-Message "Level: $($raw.level)" -Type Verbose
        }
        if ($raw.color_space) {
            Write-Message "Color Space: $($raw.color_space)" -Type Verbose
        }
        if ($raw.color_range) {
            Write-Message "Color Range: $($raw.color_range)" -Type Verbose
        }
        if ($raw.field_order) {
            Write-Message "Field Order: $($raw.field_order)" -Type Verbose
        }
        if ($raw.has_b_frames) {
            Write-Message "B-Frames: $($raw.has_b_frames)" -Type Verbose
        }
        if ($raw.nb_frames) {
            Write-Message "Frame Count: $($raw.nb_frames)" -Type Verbose
        }
    }
}
function Show-AudioTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaStream]$Track,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $raw = $Track.Raw
    # Basic audio properties
    if ($raw.sample_rate) {
        Write-Message "Sample Rate: $($raw.sample_rate) Hz" -Type Info
    }
    if ($raw.channels) {
        Write-Message "Channels: $($raw.channels)" -Type Info
    }
    if ($raw.channel_layout) {
        Write-Message "Channel Layout: $($raw.channel_layout)" -Type Info
    }
    if ($raw.profile) {
        Write-Message "Profile: $($raw.profile)" -Type Info
    }
    if ($raw.sample_fmt) {
        Write-Message "Sample Format: $($raw.sample_fmt)" -Type Info
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($raw.bits_per_sample) {
            Write-Message "Bits Per Sample: $($raw.bits_per_sample)" -Type Verbose
        }
        if ($raw.initial_padding) {
            Write-Message "Initial Padding: $($raw.initial_padding)" -Type Verbose
        }
        if ($raw.nb_frames) {
            Write-Message "Frame Count: $($raw.nb_frames)" -Type Verbose
        }
    }
}
function Show-SubtitleTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaStream]$Track,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $raw = $Track.Raw
    # Basic subtitle properties
    if ($raw.width -and $raw.height) {
        Write-Message "Dimensions: $($raw.width)x$($raw.height)" -Type Info
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($raw.start_time -and $raw.start_time -ne '0.000000') {
            Write-Message "Start Time: $($raw.start_time)s" -Type Verbose
        }
        if ($raw.duration -and $raw.duration -ne 'N/A') {
            Write-Message "Duration: $($raw.duration)s" -Type Verbose
        }
    }
}
function Show-DataTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaStream]$Track,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $raw = $Track.Raw
    # Basic data properties
    if ($raw.start_time -and $raw.start_time -ne '0.000000') {
        Write-Message "Start Time: $($raw.start_time)s" -Type Info
    }
    if ($raw.duration -and $raw.duration -ne 'N/A') {
        Write-Message "Duration: $($raw.duration)s" -Type Info
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($raw.bit_rate) {
            Write-Message "Bitrate: $([math]::Round($raw.bit_rate / 1000, 1)) kbps" -Type Verbose
        }
    }
}
