# Testing script
[CmdletBinding()]
param (
    [Parameter()]
    [switch]$CallOperator,
    [switch]$InvokeExpression,
    [switch]$StartProcess,
    [switch]$DotNetProcess,
    [switch]$DotNetProcessAsync,
    [switch]$DotNetProcessAsync2,
    [string]$DotNetFileName = $null,
    [string]$DotNetArgumentString = $null,
    [string[]]$DotNetArguments = $null
)

if ($CallOperator) {
    # Call Operator
    Write-Host '--- CALL OPERATOR: START ----------------------------' -ForegroundColor Cyan
    Write-Host 'Call operator'
    $status = & git status
    Write-Host "status: $status"
    Write-Host '--- CALL OPERATOR: END ------------------------------' -ForegroundColor Cyan
}

if ($InvokeExpression) {
    # Invoke-Expression
    Write-Host '--- INVOKE-EXPRESSION: START ------------------------' -ForegroundColor Cyan
    # Build and execute dynamic command
    $cmd = 'ping 8.8.8.8 -n 2'
    Invoke-Expression $cmd
    Write-Host '--- INVOKE-EXPRESSION: END --------------------------' -ForegroundColor Cyan
}

if ($StartProcess) {
    # Start Process
    Write-Host '--- START-PROCESS: START ----------------------------' -ForegroundColor Cyan 

    Write-Host ' **  NOTEPAD **'
    # Launch Notepad, wait for exit, retrieve exit code
    $p = Start-Process notepad -Wait -NoNewWindow -PassThru
    $exitCode = $p.ExitCode
    Write-Host "     exitCode: $exitCode **"

    Write-Host ' **  PING **'
    # Launch Notepad, wait for exit, retrieve exit code
    Start-Process ping -ArgumentList '8.8.8.8', '-n', '2' -NoNewWindow -RedirectStandardOutput out.txt -Wait
    Write-Host '     out.txt **'
    Get-Content out.txt

    Write-Host '--- START-PROCESS: END ------------------------------' -ForegroundColor Cyan
}

if ($DotNetProcess) {
    # System.Diagnostics.Process
    Write-Host '--- .NET PROCESS: START -----------------------------' -ForegroundColor Cyan

    #$FileName = 'ping'
    #$Arguments = @('8.8.8.8', '-n', '2')
    #$ArgumentsString = $Arguments -join ' '

    Write-Host '** Arguments **' -ForegroundColor Green
    if ([String]::IsNullOrWhiteSpace($DotNetFileName)) {
        $Value = 'ping'
        Write-Host "   DotNetFileName is null/empty/whitespace, setting to '$Value'"
        $DotNetFileName = $Value
    }
    if ([String]::IsNullOrWhiteSpace($DotNetArgumentString)) {
        $Value = '8.8.8.8 -n 2'
        Write-Host "   DotNetArgumentString is null/empty/whitespace, setting to '$Value'"
        $DotNetArgumentString = $Value
    }
    if ([String]::IsNullOrWhiteSpace($DotNetArguments)) {
        $Value = @('8.8.8.8', '-n', '2')
        Write-Host "   DotNetArguments is null/empty/whitespace, setting to '$($Value | ConvertTo-Json -Compress)'"
        $DotNetArguments = $Value
    }

    Write-Host '** ProcessStartInfo **' -ForegroundColor Green
    Write-Host '   New-Object System.Diagnostics.ProcessStartInfo'
    $si = New-Object System.Diagnostics.ProcessStartInfo
    Write-Host "   si.FileName = $DotNetFileName"
    $si.FileName = $DotNetFileName
    Write-Host "   si.Arguments = $ArgumentsString"
    $si.Arguments = $DotNetArgumentString
    Write-Host "   si.RedirectStandardOutput = $true"
    $si.RedirectStandardOutput = $true
    Write-Host "   si.UseShellExecute = $false"
    $si.UseShellExecute = $false

    Write-Host '** Process **' -ForegroundColor Green
    Write-Host '   p = [System.Diagnostics.Process]::Start($si)'
    $p = [System.Diagnostics.Process]::Start($si)

    Write-Host '** StandardOutput **' -ForegroundColor Green
    Write-Host '   $p.StandardOutput.ReadToEnd()'
    $output = $p.StandardOutput.ReadToEnd()
    Write-Host "output: $output"

    Write-Host '** WaitForExit **' -ForegroundColor Green
    Write-Host '   $p.WaitForExit()'
    $p.WaitForExit()

    Write-Host '--- .NET PROCESS: END -------------------------------' -ForegroundColor Cyan
}

if ($DotNetProcessAsync) {
    try {
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC START ---------------' -ForegroundColor Cyan

        #$FileName = 'ffprobe'
        #$Arguments = @('-v', 'error', '-of', 'json', '-show_streams', '"C:\Video-C\Alias\Season 01\Alias {tvdb 180267} - s01e01.mkv"')
        #$ArgumentsString = $Arguments -join ' '

        Write-Host '** Arguments **' -ForegroundColor Green
        if ([String]::IsNullOrWhiteSpace($DotNetFileName)) {
            $value = 'ffprobe'
            Write-Host "   DotNetFileName is null/empty/whitespace, setting to '$value'"
            $DotNetFileName = $value
        }
        if ([String]::IsNullOrWhiteSpace($DotNetArgumentString)) {
            $value = '-v error -of json -show_streams `"C:\Video-C\Alias\Season 01\Alias {tvdb 180267} - s01e01.mkv`"'
            Write-Host "   DotNetArgumentString is null/empty/whitespace, setting to '$value'"
            $DotNetArgumentString = $value
        }
        if ([String]::IsNullOrWhiteSpace($DotNetArguments)) {
            $value = @('-v', 'error', '-of', 'json', '-show_streams', '"C:\Video-C\Alias\Season 01\Alias {tvdb 180267} - s01e01.mkv"')
            Write-Host "   DotNetArguments is null/empty/whitespace, setting to '$($value | ConvertTo-Json -Compress)'"
            $DotNetArguments = $value
        }
    
        Write-Host 'New-Object System.Diagnostics.ProcessStartInfo'
        Write-Host '** ProcessStartInfo **' -ForegroundColor Green
        $si = New-Object System.Diagnostics.ProcessStartInfo
        $si = New-Object System.Diagnostics.ProcessStartInfo
        Write-Host "   si.FileName = $DotNetFileName"
        $si.FileName = $DotNetFileName
        Write-Host "   si.Arguments = $ArgumentsString"
        $si.Arguments = $DotNetArgumentString
        Write-Host "   si.UseShellExecute = $false"
        $si.UseShellExecute = $false

        Write-Host '** Process **' -ForegroundColor Green
        Write-Host '   p = [System.Diagnostics.Process]::Start($si)'
        $p = [System.Diagnostics.Process]::Start($si)

        # Read output streams asynchronously to prevent deadlocks
        Write-Host '** StandardOutput/StandardError **' -ForegroundColor Green
        Write-Host '   StandardOutput' -ForegroundColor Green
        Write-Host '   Setting up StandardOut async job'
        if ($p.StandardOutput -ne $null) {
            Write-Host "   p.StandardOutput.GetType(): $($p.StandardOutput.GetType())"
            Write-Host '   outputJob = p.StandardOutput.ReadToEndAsync()'
            Write-Host '   $outputJob = $p.StandardOutput.ReadToEndAsync() -as [System.Threading.Tasks.Task[string]]'
            $outputJob = $p.StandardOutput.ReadToEndAsync() -as [System.Threading.Tasks.Task[string]]
        }
        else {
            Write-Host '   p.StandardOutput is null'
            $outputJob = $null
        }

        Write-Host '   StandardError **' -ForegroundColor Green
        Write-Host '   Setting up StandardError async job'
        if ($p.StandardError -ne $null) {
            Write-Host "   p.StandardError.GetType(): $($p.StandardError.GetType())"
            Write-Host '   errorJob =p.StandardError.ReadToEndAsync() -as [System.Threading.Tasks.Task[string]]'
            $errorJob = $p.StandardError.ReadToEndAsync() -as [System.Threading.Tasks.Task[string]]
        }
        else {
            Write-Host '   p.StandardError is null'
            $errorJob = $null
            'XXX Output'
            $p.StandardError.Foo
        }

        Write-Host '** WaitForExit' -ForegroundColor Green
        Write-Host '   $p.WaitForExit()'
        $p.WaitForExit()

        Write-Host '** Output **' -ForegroundColor Green
        Write-Host '   Getting StandardOutput.Result'
        $standardOutput = $outputJob.Result ?? [string]::Empty
        Write-Host "standardOutput.Length: $($standardOutput.Length)" -ForegroundColor Cyan
        Write-Host "standardOutput.GetType(): $($standardOutput.GetType())" -ForegroundColor Cyan
        if ($standardOutput.Length -gt 0) {
            Write-Host "standardOutput: $($standardOutput.Substring(0, [Math]::Min(80, $standardOutput.Length)))" -ForegroundColor Cyan
        }
        else {
            Write-Host 'standardOutput: (empty)' -ForegroundColor Cyan
        }

        Write-Host '   Getting StandardError.Result'
        $standardError = $errorJob.Result ?? [string]::Empty
        Write-Host "standardError.Length: $($standardError.Length)" -ForegroundColor Cyan
        Write-Host "standardError.GetType(): $($standardError.GetType())" -ForegroundColor Cyan
        if ($standardError.Length -gt 0) {
            Write-Host "standardError: $($standardError.Substring(0, [Math]::Min(80, $standardError.Length)))" -ForegroundColor Cyan
        }
        else {
            Write-Host 'standardError: (empty)' -ForegroundColor Cyan
        }

        # Close the process to free up resources
        Write-Host '** Close **' -ForegroundColor Green
        Write-Host '   p.Close()'
        $p.Close()

        $result = [PSCustomObject]@{
            Output   = $standardOutput
            Error    = $standardError
            ExitCode = $p.ExitCode
        }


        Write-Host '** Return **' -ForegroundColor Green
        Write-Host '   result = [PSCustomObject]@{'
        Write-Host "      Output   = $($standardOutput.Substring(0, [Math]::Min(80, $standardOutput.Length)))"
        Write-Host "      Error    = $($standardError.Substring(0, [Math]::Min(80, $standardError.Length)))"
        Write-Host "      ExitCode = $($p.ExitCode)"
        Write-Host '}'

        Write-Host '--- .NET PROCESS: FFPROBE ASYNC END -----------------' -ForegroundColor Cyan
    }
    catch {
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC EXCEPTION START ------' -ForegroundColor Red
        Write-Host "   `$_.GetType(): $($_.GetType())" -ForegroundColor Red
        Write-Host "   `$_.Exception.GetType(): $($_.Exception.GetType())" -ForegroundColor Red
        #    Write-Host "Message: $($_.Exception.Message | ConvertTo-Json -Compress)" -ForegroundColor Red
        Write-Host "   FullyQualifiedErrorId: $($_.FullyQualifiedErrorId)" -ForegroundColor Red
        Write-Host "   ScriptStackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
        Write-Host "   CategoryInfo: $($_.CategoryInfo)" -ForegroundColor Red
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC EXCEPTION END --------' -ForegroundColor Red
    }
    finally {
    }
}

if ($DotNetProcessAsync2) {
    try {
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC2 START ---------------' -ForegroundColor Cyan

        $args = @('-v', 'error', '-of', 'json', '-show_streams', '"C:\Video-C\Alias\Season 01\Alias {tvdb 180267} - s01e01.mkv"')

        #        $psi.Arguments = $escapedArgs -join ' '
        # Set up process start info
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'ffprobe'
        $psi.Arguments = $args -join ' '
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        # Start the process
        $proc = [System.Diagnostics.Process]::Start($psi)

        # Read both streams (these block until the process exits or streams close)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()

        $proc.WaitForExit()

        # Output the captured strings
        Write-Host "`n=== STANDARD OUTPUT ===`n" -ForegroundColor Cyan
        Write-Host $stdout -ForegroundColor Gray

        Write-Host "`n=== STANDARD ERROR ===`n" -ForegroundColor Magenta
        Write-Host $stderr -ForegroundColor Red

        Write-Host "`nProcess exited with code $($proc.ExitCode)" -ForegroundColor Green
        <#
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.EnableRaisingEvents = $true

        # Define event handlers
        $proc.add_OutputDataReceived({
                if ($_.Data) {
                    Write-Host "OUT > $($_.Data)"
                }
            })

        $proc.add_ErrorDataReceived({
                if ($_.Data) {
                    Write-Host "ERR > $($_.Data)" -ForegroundColor Red
                }
            })

        $proc.add_Exited({
                Write-Host "`nProcess exited with code $($proc.ExitCode)`n" -ForegroundColor Green
            })

        # Start asynchronously
        $proc.Start() | Out-Null
        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()

        # Meanwhile, PowerShell remains responsive
        Write-Host 'Process is running asynchronously. You can do other work...'
        #>
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC2 END -----------------' -ForegroundColor Cyan
    }
    catch {
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC2 EXCEPTION START -----' -ForegroundColor Red
        Write-Host "   `$_.GetType(): $($_.GetType())" -ForegroundColor Red
        Write-Host "   `$_.Exception.GetType(): $($_.Exception.GetType())" -ForegroundColor Red
        #    Write-Host "Message: $($_.Exception.Message | ConvertTo-Json -Compress)" -ForegroundColor Red
        Write-Host "   FullyQualifiedErrorId: $($_.FullyQualifiedErrorId)" -ForegroundColor Red
        Write-Host "   ScriptStackTrace: $($_.ScriptStackTrace)" -ForegroundColor Red
        Write-Host "   CategoryInfo: $($_.CategoryInfo)" -ForegroundColor Red
        Write-Host '--- .NET PROCESS: FFPROBE ASYNC2 EXCEPTION END -------' -ForegroundColor Red
    }
    finally {
    }
}