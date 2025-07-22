function Format-MediaTrack {
    <#
    .SYNOPSIS
        Formats media tracks into structured objects for programmatic use.
    .DESCRIPTION
        Format-MediaTrack converts MediaTrack objects into formatted PSCustomObjects
        with type-specific properties organized for easy consumption by other functions
        or for export to various formats (CSV, JSON, etc.).
        The function creates objects with common properties shared across all track types,
        plus type-specific properties relevant to each track type.
    .PARAMETER Track
        The MediaTrack object(s) to format. Can be a single track or an array of tracks.
    .PARAMETER DetailLevel
        The level of detail to include in the output. Valid values are 'Basic', 'Detailed', and 'Full'.
        Default is 'Detailed'.
    .PARAMETER TrackType
        Filter to format only specific track types. Valid values are 'Video', 'Audio', 'Subtitle', 'Data', 'All'.
        Default is 'All'.
    .EXAMPLE
        Get-MediaTrack -Path "C:\video.mkv" | Format-MediaTrack | Format-Table -AutoSize
        Formats all tracks and displays them in a table format.
    .EXAMPLE
        Get-MediaTrack -Path "C:\video.mkv" | Format-MediaTrack -TrackType Video | Export-Csv -Path "video_tracks.csv"
        Formats only video tracks and exports them to CSV.
    .EXAMPLE
        $formattedTracks = Get-MediaTrack -Path "C:\video.mkv" | Format-MediaTrack -DetailLevel Full
        $formattedTracks | ConvertTo-Json -Depth 10 | Out-File "tracks.json"
        Formats all tracks with full detail and exports to JSON.
    .OUTPUTS
        [PSCustomObject[]] - Array of formatted track objects with type-specific properties.
    .NOTES
        This function is designed for programmatic use and data export, while Show-MediaTrack
        is designed for human-readable console output.
    .LINK
        Get-MediaTrack
        Show-MediaTrack
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [MediaTrack]$Track,
        [Parameter()]
        [ValidateSet('Basic', 'Detailed', 'Full')]
        [string]$DetailLevel = 'Detailed',
        [Parameter()]
        [ValidateSet('Video', 'Audio', 'Subtitle', 'Data', 'All')]
        [string]$TrackType = 'All'
    )
    begin {
        $allTracks = [System.Collections.ArrayList]::new()
        Write-Message "Initializing media track formatting with DetailLevel: $DetailLevel, TrackType: $TrackType" -Type Verbose
    }
    process {
        if ($TrackType -eq 'All' -or $Track.Type -eq $TrackType) {
            $null = $allTracks.Add($Track)
        }
    }
    end {
        if ($allTracks.Count -eq 0) {
            Write-Message 'No tracks found matching the specified criteria' -Type Warning
            return @()
        }
        Write-Message "Formatting $($allTracks.Count) track(s)" -Type Verbose
        $formattedTracks = foreach ($track in $allTracks) {
            Format-SingleTrack -Track $track -DetailLevel $DetailLevel
        }
        return $formattedTracks
    }
}
function Format-SingleTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaTrack]$Track,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $raw = $Track.Raw
    # Common properties for all track types
    $commonProps = @{
        Index    = $Track.Index
        Type     = $Track.Type
        Codec    = $Track.Codec
        Language = $Track.Language
        Title    = $Track.Title
        Duration = $Track.Duration
        Bitrate  = $Track.Bitrate
    }
    $allProps = $commonProps

    # Type-specific properties
    $typeProps = switch ($Track.Type) {
        'video' {
            Get-VideoTrackProperties -Raw $raw -DetailLevel $DetailLevel
        }
        'audio' {
            Get-AudioTrackProperties -Raw $raw -DetailLevel $DetailLevel
        }
        'subtitle' {
            Get-SubtitleTrackProperties -Raw $raw -DetailLevel $DetailLevel
        }
        'data' {
            Get-DataTrackProperties -Raw $raw -DetailLevel $DetailLevel
        }
    }
    # Combine common and type-specific properties
    foreach ($kvp in $typeProps.GetEnumerator()) {
        $allProps[$kvp.Key] = $kvp.Value
    }

    # Add raw data for Full detail level
    if ($DetailLevel -eq 'Full') {
        $allProps['RawData'] = $raw
    }
    return [PSCustomObject]$allProps
}
function Get-VideoTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Raw,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $props = @{}
    # Basic video properties
    if ($Raw.width -and $Raw.height) {
        $props['Resolution'] = "$($Raw.width)x$($Raw.height)"
        $props['Width'] = $Raw.width
        $props['Height'] = $Raw.height
    }
    if ($Raw.profile) {
        $props['Profile'] = $Raw.profile
    }
    if ($Raw.pix_fmt) {
        $props['PixelFormat'] = $Raw.pix_fmt
    }
    if ($Raw.r_frame_rate -and $Raw.r_frame_rate -ne '0/0') {
        $props['FrameRate'] = $Raw.r_frame_rate
    }
    if ($Raw.avg_frame_rate -and $Raw.avg_frame_rate -ne '0/0') {
        $props['AverageFrameRate'] = $Raw.avg_frame_rate
    }
    if ($Raw.display_aspect_ratio) {
        $props['AspectRatio'] = $Raw.display_aspect_ratio
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($Raw.level) {
            $props['Level'] = $Raw.level
        }
        if ($Raw.color_space) {
            $props['ColorSpace'] = $Raw.color_space
        }
        if ($Raw.color_range) {
            $props['ColorRange'] = $Raw.color_range
        }
        if ($Raw.field_order) {
            $props['FieldOrder'] = $Raw.field_order
        }
        if ($Raw.has_b_frames) {
            $props['HasBFrames'] = $Raw.has_b_frames
        }
        if ($Raw.nb_frames) {
            $props['FrameCount'] = $Raw.nb_frames
        }
        if ($Raw.coded_width -and $Raw.coded_height) {
            $props['CodedResolution'] = "$($Raw.coded_width)x$($Raw.coded_height)"
        }
        if ($Raw.sample_aspect_ratio) {
            $props['SampleAspectRatio'] = $Raw.sample_aspect_ratio
        }
    }
    return $props
}
function Get-AudioTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Raw,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $props = @{}
    # Basic audio properties
    if ($Raw.sample_rate) {
        $props['SampleRate'] = $Raw.sample_rate
    }
    if ($Raw.channels) {
        $props['Channels'] = $Raw.channels
    }
    if ($Raw.channel_layout) {
        $props['ChannelLayout'] = $Raw.channel_layout
    }
    if ($Raw.profile) {
        $props['Profile'] = $Raw.profile
    }
    if ($Raw.sample_fmt) {
        $props['SampleFormat'] = $Raw.sample_fmt
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($Raw.bits_per_sample) {
            $props['BitsPerSample'] = $Raw.bits_per_sample
        }
        if ($Raw.initial_padding) {
            $props['InitialPadding'] = $Raw.initial_padding
        }
        if ($Raw.nb_frames) {
            $props['FrameCount'] = $Raw.nb_frames
        }
    }
    return $props
}
function Get-SubtitleTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Raw,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $props = @{}
    # Basic subtitle properties
    if ($Raw.width -and $Raw.height) {
        $props['Dimensions'] = "$($Raw.width)x$($Raw.height)"
        $props['Width'] = $Raw.width
        $props['Height'] = $Raw.height
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($Raw.start_time -and $Raw.start_time -ne '0.000000') {
            $props['StartTime'] = $Raw.start_time
        }
        if ($Raw.duration -and $Raw.duration -ne 'N/A') {
            $props['Duration'] = $Raw.duration
        }
    }
    return $props
}
function Get-DataTrackProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Raw,
        [Parameter(Mandatory)]
        [string]$DetailLevel
    )
    $props = @{}
    # Basic data properties
    if ($Raw.start_time -and $Raw.start_time -ne '0.000000') {
        $props['StartTime'] = $Raw.start_time
    }
    if ($Raw.duration -and $Raw.duration -ne 'N/A') {
        $props['Duration'] = $Raw.duration
    }
    # Detailed properties
    if ($DetailLevel -in 'Detailed', 'Full') {
        if ($Raw.bit_rate) {
            $props['Bitrate'] = $Raw.bit_rate
        }
    }
    return $props
} 
