class FFProbeResult {
    <#
    .SYNOPSIS
        Represents the result of an ffprobe process execution with JSON parsing.

    .DESCRIPTION
        This class contains the output, error, exit code, and parsed JSON data from ffprobe.
        It provides a standardized way to handle ffprobe results.

    .PROPERTY Output
        The standard output from the process as a string.

    .PROPERTY Error
        The standard error output from the process as a string.

    .PROPERTY ExitCode
        The exit code returned by the process as an integer.

    .PROPERTY Json
        The parsed JSON object from the ffprobe output. This will be null if the process
        failed or if the output could not be parsed as JSON.

    .EXAMPLE
        $result = Invoke-FFProbe @('-show_program_version')
        if ($result.IsSuccess()) {
            Write-Host "FFProbe version: $($result.Json.program_version.version)"
        } else {
            Write-Error "FFProbe failed: $($result.Error)"
        }

    .NOTES
        This class is used by Invoke-FFProbe to provide a consistent return type that
        includes both the raw process result and the parsed JSON data.
    #>

    # Properties
    [string]$Output
    [string]$Error
    [int]$ExitCode
    [PSCustomObject]$Json

    # Constructor
    FFProbeResult([string]$Output, [string]$Error, [int]$ExitCode, [PSCustomObject]$Json) {
        $this.Output = $Output
        $this.Error = $Error
        $this.ExitCode = $ExitCode
        $this.Json = $Json
    }

    # Method to check if the process succeeded
    [bool]IsSuccess() {
        return $this.ExitCode -eq 0
    }

    # Method to check if the process failed
    [bool]IsFailure() {
        return $this.ExitCode -ne 0
    }

    # Override ToString method for better debugging
    [string]ToString() {
        $jsonInfo = if ($this.Json) { "HasJson" } else { "NoJson" }
        return "FFProbeResult{ExitCode=$($this.ExitCode), $jsonInfo, OutputLength=$($this.Output.Length), ErrorLength=$($this.Error.Length)}"
    }
} 