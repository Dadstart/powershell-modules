function Export-VideoItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter(Mandatory)]
        [string[]]$CopiedFiles,

        [Parameter(Mandatory)]
        [scriptblock]$Command,

        [Parameter(Mandatory)]
        [ValidateSet('Chapter', 'Caption')]
        [string]$ItemType
    )

    Write-Message "Path: $Path" -Type Debug
    Write-Message "Destination: $Destination" -Type Debug
    Write-Message "CopiedFiles ($($CopiedFiles.Count)): $CopiedFiles)" -Type Debug
    Write-Message "Command: $Command" -Type Debug
    Write-Message "ItemType: $ItemType" -Type Debug

    Write-Message "🎬 $ItemType extraction phase" -Type Processing
    if ($CopiedFiles.Count -gt 0) {
        # Create output directory if it doesn't exist
        New-ProcessingDirectory -Path $Destination -Description $ItemType -SuppressOutput | Out-Null

        return Invoke-Command $Command
    }
    else {
        return $null
    }
}
