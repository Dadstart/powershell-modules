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
    [OutputType([ProcessResult])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(Mandatory = $false, Position = 1)]
        [string[]]$Arguments = @()
    )

    Write-Verbose "Invoke-Process: STARTING - Name: $Name"
    Write-Verbose "Invoke-Process: Arguments: $($Arguments -join ' ')"
 
    try {
        # Set up process start info
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Name
        
        # Properly quote arguments to handle paths with spaces
        $quotedArguments = $Arguments | ForEach-Object {
            if ($_ -match '\s' -and $_ -notmatch '^".*"$') {
                # Quote arguments that contain spaces and aren't already quoted
                "`"$_`""
            } else {
                $_
            }
        }
        $psi.Arguments = $quotedArguments -join ' '
        
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        
        # Create and start the process
        $proc = [System.Diagnostics.Process]::new()
        $proc.StartInfo = $psi
        $proc.Start()

        # Read both streams asynchronously to prevent deadlocks
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        
        Write-Verbose 'Invoke-Process: process.WaitForExit()'
        $proc.WaitForExit()
        
        # Get the results from the async tasks
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result
        Write-Verbose "Invoke-Process: Process exited with code $($proc.ExitCode)"
        Write-Debug "Invoke-Process: stdout length: $($stdout.Length)"
        Write-Debug "Invoke-Process: stderr length: $($stderr.Length)"

        # Check for errors
        $exitCode = $proc.ExitCode
        if ($exitCode -ne 0) {
            Write-Warning "Invoke-Process: Process Failed`n`tExecutable: $Name`n`tArguments: $($psi.Arguments)`n`tExit Code: $exitCode`n`tError: $stderr"
        }

        # Dispose the process to free up resources
        Write-Verbose 'Invoke-Process: Disposing Process'
        $proc.Dispose()
        Write-Verbose 'Invoke-Process: Process Disposed'

        # Create and return ProcessResult object
        $result = [ProcessResult]::new($stdout, $stderr, $exitCode)
        return $result
    }
    catch {
        Write-Verbose 'Invoke-Process: Exception'
        Write-Verbose "Invoke-Process: Error: $($_)"
        Write-Verbose "Invoke-Process: Message: $($_.Exception.Message)"
        Write-Verbose "Invoke-Process: FullyQualifiedErrorId: $($_.FullyQualifiedErrorId)"
        Write-Verbose "Invoke-Process: ScriptStackTrace: $($_.ScriptStackTrace)"
        Write-Verbose "Invoke-Process: CategoryInfo: $($_.CategoryInfo)"
        throw $_
    }
}