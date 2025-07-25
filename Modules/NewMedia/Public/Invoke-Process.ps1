function Invoke-Process {
    <#
    .SYNOPSIS
        Invokes a process with the specified arguments.
    .DESCRIPTION
        This function invokes a process with the specified arguments and returns a ProcessResult object.
        It provides better error handling and output capture than the standard Start-Process.
    .PARAMETER Name
        The name of the process to invoke.
    .PARAMETER Arguments
        The arguments to pass to the process.
    .RETURNVALUE
        [ProcessResult]@{
            Output   = [string] (Standard Output)
            Error    = [string] (Standard Error)
            ExitCode = [int] (Exit Code)
        }
    .EXAMPLE
        $result = Invoke-Process 'ffprobe' @('-version')
        if ($result.IsSuccess()) {
            Write-Host "Process succeeded: $($result.Output)"
        } else {
            Write-Error "Process failed: $($result.Error)"
        }
    .OUTPUTS
        [ProcessResult]
        Returns a ProcessResult object containing the output, error, and exit code.
    .NOTES
        This is an internal helper function used by other module functions.
        It provides better error handling and output capture than standard PowerShell process invocation.
        The returned ProcessResult object includes methods like IsSuccess() and IsFailure() for easy status checking.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory = $false, Position = 1)]
        [string[]]$Arguments = @()
    )
    Write-Message "Invoke-Process: STARTING - Name: $Name" -Type Verbose
    Write-Message "Invoke-Process: Arguments: $($Arguments -join ' ')" -Type Verbose

    try {
        # Set up process start info
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Name
        # Properly quote arguments to handle paths with spaces
        $quotedArguments = $Arguments | ForEach-Object {
            $arg = $_

            # Check if the argument is already properly quoted (starts and ends with quotes)
            if ($arg -match '^".*"$') {
                return $arg
            }

            # Check if the argument contains whitespace that needs quoting
            if ($arg -match '\s') {
                # Check if it's a key=value pair with quoted value containing spaces
                if ($arg -match '^([^=]+)="([^"]*\s[^"]*)"(.*)$') {
                    # This is already properly formatted with quotes around the value
                    return $arg
                }
                else {
                    # Quote the entire argument
                    return "`"$arg`""
                }
            }

            return $arg
        }
        $psi.Arguments = $quotedArguments -join ' '
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        # Create and start the process
        $proc = [System.Diagnostics.Process]::new()
        $proc.StartInfo = $psi
        if (-not $proc.Start()) {
            Write-Message "Invoke-Process: Process Failed`n`tExecutable: $Name`n`tArguments: $($psi.Arguments)`n`tExit Code: $($proc.ExitCode)`n`tError: $($proc.StandardError.ReadToEnd())" -Type Error
            throw "Process Failed: $Name $($psi.Arguments)"
        }

        # Read both streams asynchronously to prevent deadlocks
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        Write-Message 'Invoke-Process: process.WaitForExit()' -Type Verbose
        $proc.WaitForExit()
        # Get the results from the async tasks
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result
        Write-Message "Invoke-Process: Process exited with code $($proc.ExitCode)" -Type Verbose
        Write-Message "Invoke-Process: stdout length: $($stdout.Length)" -Type Debug
        Write-Message "Invoke-Process: stderr length: $($stderr.Length)" -Type Debug
        # Check for errors
        $exitCode = $proc.ExitCode
        if ($exitCode -ne 0) {
            Write-Warning "Invoke-Process: Process Failed`n`tExecutable: $Name`n`tArguments: $($psi.Arguments)`n`tExit Code: $exitCode`n`tError: $stderr"
        }
        # Dispose the process to free up resources
        Write-Message 'Invoke-Process: Disposing Process' -Type Verbose
        $proc.Dispose()
        Write-Message 'Invoke-Process: Process Disposed' -Type Verbose
        # Create and return ProcessResult object
        return [PSCustomObject]@{
            Output      = $stdout
            ErrorOutput = $stderr
            ExitCode    = $exitCode
        }
    }
    catch {
        Write-Message 'Invoke-Process: Exception' -Type Error
        Write-Message "Invoke-Process: Error: $($_)" -Type Error
        Write-Message "Invoke-Process: Message: $($_.Exception.Message)" -Type Error
        Write-Message "Invoke-Process: FullyQualifiedErrorId: $($_.FullyQualifiedErrorId)" -Type Error
        Write-Message "Invoke-Process: ScriptStackTrace: $($_.ScriptStackTrace)" -Type Error
        Write-Message "Invoke-Process: CategoryInfo: $($_.CategoryInfo)" -Type Error
        throw $_
    }
}
