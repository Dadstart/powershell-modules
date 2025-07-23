function Invoke-FFProbe {
    <#
    .SYNOPSIS
        Retrieves a ProcessResult object from the JSON output of ffprobe.
    .DESCRIPTION
        This function runs ffprobe on the specified media file and returns a ProcessResult object
        that contains the raw process result. The output can be parsed as JSON using the FromJson() method.
    .PARAMETER Arguments
        Arguments to pass to ffprobe.
    .RETURNVALUE
        [ProcessResult]@{
            Output   = [string] (Standard Output)
            ErrorOutput = [string] (Standard Error)
            ExitCode = [int] (Exit Code)
        }
    .EXAMPLE
        $result = Invoke-FFProbe @('-show_program_version')
        Write-Host "FFProbe version: $($result.Json.program_version.version)"
        if ($result.ExitCode -ne 0) {
            Write-Error "FFProbe failed: $($result.ErrorOutput)"
        }
    .EXAMPLE
        $result = Invoke-FFProbe @('-show_streams', '-i', 'video.mp4')
        Write-Host "Found $($result.Json.streams.Count) streams in video.mp4"
        }
    .OUTPUTS
        [PSCustomObject]@ {}
            Output = [string] (Standard Output)
            Error = [string] (Standard Error)
            ExitCode = [int] (Exit Code)
            Json = [PSCustomObject] (JSON Output)
        }
    .NOTES
        This function requires ffmpeg to be installed and available in the system PATH.
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
        $result = Invoke-Process ffprobe $finalArguments
        Write-Message "Invoke-FFProbe: Process exit code: $($result?.ExitCode)" -Type Debug
        Write-Message "Invoke-FFProbe: Output length: $($result.Output?.Length)" -Type Debug
        if ($result.ExitCode -ne 0) {
            Write-Message "Invoke-FFProbe: Failed to execute ffprobe. Exit code: $($result.ExitCode)" -Type Error
            Write-Message "Invoke-FFProbe: Error: $($result.ErrorOutput)" -Type Debug
        }
        return [PSCustomObject]@{
            Output = $result.Output
            ErrorOutput = $result.ErrorOutput
            ExitCode = $result.ExitCode
            Json = $result.Output | ConvertFrom-Json -Depth 10
        }
    }
}
