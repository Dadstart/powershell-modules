function Get-EnhancedTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseTitle,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Filename,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateCount(1, [int]::MaxValue)]
        [PSCustomObject[]]$EpisodeInfo
    )
    try {
        $episodeInfo = Get-EpisodeInfoFromFilename -Filename $Filename -EpisodeInfo $EpisodeInfo
        if ($episodeInfo) {
            # Sanitize episode title for filename (remove invalid characters)
            $sanitizedTitle = $episodeInfo.Title -replace '[<>:"/\\|?*]', ''
            return "$BaseTitle - $sanitizedTitle"
        }
        return $BaseTitle
    }
    catch {
        Write-Message "Failed to get enhanced title: $($_.Exception.Message)" -Type Error
        return $BaseTitle
    }
} 
