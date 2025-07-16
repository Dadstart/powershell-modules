function Invoke-CheckedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,
        [Parameter(Position = 1)]
        [string]$ErrorMessage = "Command failed"
    )
    try {
        Write-Message "Executing command: $Command" -Type Verbose
        $output = & $Command 2>&1
        Write-Message "Command completed with exit code: $LASTEXITCODE" -Type Verbose
        if ($output) {
            Write-Message "Command produced output, displaying it" -Type Verbose
            if ($VerbosePreference -ne 'SilentlyContinue') {
                $output -split "`n" | ForEach-Object { Write-Message $_ -Type Verbose }
            }
        } else {
            Write-Message "Command produced no output" -Type Verbose
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Message "Command failed with exit code: $LASTEXITCODE" -Type Verbose
            Write-Message $ErrorMessage -Type Verbose
            Write-Message ("Command failed with exit code " + $LASTEXITCODE + ": " + $ErrorMessage) -Type Error
            return $false
        }
        Write-Message "Command executed successfully" -Type Verbose
        return $true
    }
    catch {
        Write-Message "Invoke-CheckedCommand function failed with error: $($_.Exception.Message)" -Type Verbose
        Write-Message "Command execution failed: $($_.Exception.Message)" -Type Error
        throw "Command execution failed: $($_.Exception.Message)"
    }
} 
