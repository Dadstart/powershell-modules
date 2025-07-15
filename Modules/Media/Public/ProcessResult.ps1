class ProcessResult {
    <#
    .SYNOPSIS
        Represents the result of a process execution.

    .DESCRIPTION
        This class encapsulates the output, error, and exit code from a process execution.
        It provides a standardized way to handle process results across the module.

    .PROPERTY Output
        The standard output from the process as a string.

    .PROPERTY Error
        The standard error output from the process as a string.

    .PROPERTY ExitCode
        The exit code returned by the process as an integer.

    .EXAMPLE
        $result = Invoke-Process 'ffprobe' @('-version')
        if ($result.ExitCode -eq 0) {
            Write-Host "Process succeeded: $($result.Output)"
        } else {
            Write-Error "Process failed: $($result.Error)"
        }

    .NOTES
        This class is used by Invoke-Process and related functions to provide
        consistent return types for process execution results.
    #>

    # Properties
    [string]$Output
    [string]$Error
    [int]$ExitCode

    # Constructor
    ProcessResult([string]$Output, [string]$Error, [int]$ExitCode) {
        $this.Output = $Output
        $this.Error = $Error
        $this.ExitCode = $ExitCode
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
        return "ProcessResult{ExitCode=$($this.ExitCode), OutputLength=$($this.Output.Length), ErrorLength=$($this.Error.Length)}"
    }
} 