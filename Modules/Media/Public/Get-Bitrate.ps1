function Get-Bitrate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    process {
        Write-Message "Parameters: Path='$Path'" -Type Verbose

        try {
            # Validate file exists
            Write-Message "Validating file exists: $Path" -Type Verbose
            if (-not (Test-Path -Path $Path -PathType Leaf -ErrorAction SilentlyContinue)) {
                Write-Message "File does not exist: $Path" -Type Verbose
                Write-Message "File does not exist: $Path" -Type Error
                return $null
            }
            Write-Message 'File validation passed' -Type Verbose

            Write-Message 'Getting video stream using Get-MediaStream' -Type Verbose
            $stream = Get-MediaStream -Name $Path -Index 0 -Type Video
            Write-Message 'Retrieved video stream' -Type Verbose
        
            Write-Message 'Extracting bitrate from stream' -Type Verbose
            $bps = $stream.bit_rate
            if (-not $bps -and $stream.tags.'BPS-eng') {
                Write-Message 'Using BPS-eng tag for bitrate' -Type Verbose
                $bps = $stream.tags.'BPS-eng'
            }
        
            if ($bps) {
                Write-Message "Found bitrate: $bps bps" -Type Verbose
                return [int]$bps
            }
            else {
                Write-Message 'No bitrate found, returning 0' -Type Verbose
                return 0
            }
        }
        catch {
            Write-Message "Get-Bitrate function failed with error: $($_.Exception.Message)" -Type Verbose
            Write-Message "Failed to get bitrate: $($_.Exception.Message)" -Type Error
            throw "Failed to get bitrate: $($_.Exception.Message)"
        }
    }
}
