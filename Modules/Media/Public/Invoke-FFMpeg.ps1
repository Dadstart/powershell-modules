function Invoke-FFMpeg {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Executes ffmpeg with the specified arguments and returns a ProcessResult object.

    .DESCRIPTION
        This function runs ffmpeg with the specified arguments and returns a ProcessResult object
        containing the output, error, and exit code from the command execution.

    .PARAMETER Arguments
        Arguments to pass to ffmpeg.

    .RETURNVALUE
        [ProcessResult]@{
            Output   = [string] (Standard Output)
            Error    = [string] (Standard Error)
            ExitCode = [int] (Exit Code)
        }

    .EXAMPLE
        $result = Invoke-FFMpeg @('-version')
        if ($result.IsSuccess()) {
            Write-Host "FFMpeg version info: $($result.Output)"
        } else {
            Write-Error "FFMpeg failed: $($result.Error)"
        }

    .OUTPUTS
        [ProcessResult]
        Returns a ProcessResult object containing the output, error, and exit code.

    .NOTES
        This function requires ffmpeg to be installed and available in the system PATH.
        The returned ProcessResult object includes methods like IsSuccess() and IsFailure() for easy status checking.
    #>
    [CmdletBinding()]
    [OutputType([ProcessResult])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Arguments
    )

    begin {
        foreach ($function in @('Invoke-Process')) {
            $PSDefaultParameterValues["$function`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$function`:Debug"] = $DebugPreference
        }
   }
    process {        
        # Check if ffmpeg is installed
        Test-FFMpegInstalled -Throw | Out-Null

        $finalArguments = @('-v', 'error', '-hide_banner') + $Arguments
        Write-Verbose "Invoke-FFMpeg: Arguments: $($finalArguments -join ' ')"
        $processResult = Invoke-Process ffmpeg $finalArguments

        Write-Debug "Invoke-FFMpeg: Process exit code: $($processResult.ExitCode)"
        Write-Debug "Invoke-FFMpeg: Output length: $($processResult.Output.Length)"
        Write-Debug "Invoke-FFMpeg: Error length: $($processResult.Error.Length)"
        if ($processResult.ExitCode -ne 0) {
            Write-Error "Invoke-FFMpeg: Failed to execute ffmpeg. Exit code: $($processResult.ExitCode)"
        }

        return $processResult
    }
}