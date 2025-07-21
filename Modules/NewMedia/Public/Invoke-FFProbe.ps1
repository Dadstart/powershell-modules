function Invoke-FFProbe {
    <#
    .SYNOPSIS
        Retrieves an FFProbeResult object from the JSON output of ffprobe.
    .DESCRIPTION
        This function runs ffprobe on the specified media file and returns an FFProbeResult object
        that contains both the raw process result and the parsed JSON data.
    .PARAMETER Arguments
        Arguments to pass to ffprobe.
    .RETURNVALUE
        [FFProbeResult]@{
            Json     = [PSCustomObject] (JSON Output)
            Output   = [string] (Standard Output)
            Error    = [string] (Standard Error)
            ExitCode = [int] (Exit Code)
        }
    .EXAMPLE
        $result = Invoke-FFProbe @('-show_program_version')
        if ($result.IsSuccess()) {
            Write-Host "FFProbe version: $($result.Json.program_version.version)"
        } else {
            Write-Error "FFProbe failed: $($result.Error)"
        }
    .EXAMPLE
        $result = Invoke-FFProbe @('-show_streams', '-i', 'video.mp4')
        if ($result.IsSuccess()) {
            $streams = $result.Json.streams
            Write-Host "Found $($streams.Count) streams in video.mp4"
        }
    .OUTPUTS
        [FFProbeResult]
        Returns an FFProbeResult object containing the parsed JSON data and process result.
    .NOTES
        This function requires ffmpeg to be installed and available in the system PATH.
        The returned FFProbeResult object extends ProcessResult and includes methods like IsSuccess() and IsFailure().
        If the process fails, the Json property will be null.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Arguments
    )
    process {
        # Check if ffprobe is installed
        Test-FFMpegInstalled -Throw | Out-Null
        $finalArguments = @('-v', 'error', '-of', 'json') + $Arguments
        Write-Message "Invoke-FFProbe: Arguments: $($finalArguments -join ' ')" -Type Verbose
        $processResult = Invoke-Process ffprobe $finalArguments
        Write-Message "Invoke-FFProbe: Process exit code: $($processResult.ExitCode)" -Type Debug
        Write-Message "Invoke-FFProbe: Output length: $($processResult.Output.Length)" -Type Debug
        Write-Message "Invoke-FFProbe: Error length: $($processResult.Error.Length)" -Type Debug

        if ($processResult.ExitCode -ne 0) {
            Write-Message "Invoke-FFProbe: Failed to execute ffprobe. Exit code: $($processResult.ExitCode)" -Type Error
        }

        return $processResult
    }
}
