# Write-Message

## Next-Level Enhancements

1. Log-Level Filtering (Threshold): Prevent clutter by only emitting messages at or above a configured “minimum” level.
2. ✅ Automatic Call-Site Context: Embed where the log came from—function name, script file and line number—by peeking at $PSCmdlet.MyInvocation.
3. Pluggable “Sinks” Architecture: Instead of hard-coding streams, expose a list of scriptblocks that can handle each log entry. Users can add their own sinks (e.g. send to HTTP endpoint, syslog).
4. Async/File-Write Batching: If your script produces thousands of lines, queue them and flush in bulk to minimize disk I/O.
5. ✅ ANSI-Escape Color Support: For cross-platform terminals, switch to ANSI codes instead of Write-Host -ForegroundColor.
6. Scoped Logging / Correlation IDs: Assign a unique context ID to a block of operations to trace them end-to-end.
7. Structured Enrichers: Automatically add extra properties—machine name, user, process ID—to every JSON‐mode entry.
8. Timing & Performance Metrics: Wrap arbitrary scriptblocks to measure execution time and log it.
9. PSFramework / .NET Logging Bridge: If you need enterprise features (rolling files, async, filters), drop in a community library or bind to Microsoft.Extensions.Logging.
10. Testing & Validation with Pester: Build a Pester test suite to verify your logger honors thresholds, JSON mode, separators, context injection, etc.

## Next Steps: Adding Level-Filtering and Call-Site Context

Let’s pick two high-impact enhancements and weave them into your existing Write-Message. You’ll end up with:

- Log-Level Threshold: only messages at or above a configured minimum level get emitted.
- Automatic Call-Site Context: prefix each log entry with ScriptName:LineNumber so you always know where it came from.

### 1. Extend Your Config Object

At the top of Shared.Logging.psm1, initialize two new defaults:

```Powershell
# Module-scope: how we rank levels and our defaults
if (-not $script:LevelPriority) {
    $script:LevelPriority = @{ Debug = 0; Info = 1; Warning = 2; Error = 3 }
}

if (-not $script:WriteMessageConfig) {
    $script:WriteMessageConfig = [PSCustomObject]@{
        MinLevel        = 'Debug'      # new: the minimum Level to emit
        IncludeContext  = $false       # new: whether to prefix context
        LogFile         = $null
        TimeStamp       = $false
        Separator       = ' '
        NoHost          = $false
        AsJson          = $false
        LevelColors     = @{
            Info    = 'Green'
            Warning = 'Yellow'
            Error   = 'Red'
            Debug   = 'Cyan'
        }
    }
}
```

### 2. Update Write-MessageConfiguration

Add -MinLevel and -IncludeContext parameters so users can change these defaults:

```Powershell
function Write-MessageConfiguration {
  [CmdletBinding(DefaultParameterSetName='Set')]
  param(
    # … existing parameters …

    [Parameter(ParameterSetName='Set')]
    [ValidateSet('Debug','Info','Warning','Error')]
    [string]    $MinLevel,

    [Parameter(ParameterSetName='Set')]
    [Switch]    $IncludeContext,

    # … List/Reset parameters …
  )

  process {
    # … existing apply logic …

    if ($PSBoundParameters.ContainsKey('MinLevel')) {
      $script:WriteMessageConfig.MinLevel = $MinLevel
    }
    if ($PSBoundParameters.ContainsKey('IncludeContext')) {
      $script:WriteMessageConfig.IncludeContext = $IncludeContext.IsPresent
    }

    Write-Verbose 'Write-Message configuration updated.'
  }
}
```

### 3. Enrich Write-Message with Filtering & Context

Below is the core change to your Write-Message function:

- Filter out any $Level below the configured threshold.
- Inject ScriptName:LineNumber when context is enabled.

```Powershell
function Write-Message {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory, Position=0, ValueFromRemainingArguments)]
        [object[]] $Message,

        [ValidateSet('Info','Warning','Error','Debug')]
        [string]   $Level = 'Info',

        [string]   $LogFile,
        [Switch]   $TimeStamp,
        [string]   $Separator = ' ',
        [Switch]   $NoHost,
        [Switch]   $AsJson
    )

    process {
        # 1) Level-filtering
        $minRank = $script:LevelPriority[$script:WriteMessageConfig.MinLevel]
        if ($script:LevelPriority[$Level] -lt $minRank) { return }

        # 2) Build the raw text
        $blocks = foreach ($item in $Message) {
            if ($item -is [string]) { $item }
            else { ($item | Out-String -Width ([Console]::WindowWidth)) -replace '[\r\n]+$','' }
        }
        $text = $blocks -join (
            if ($PSBoundParameters.ContainsKey('Separator')) { $Separator }
            else { $script:WriteMessageConfig.Separator }
        )

        if (
            ($PSBoundParameters.ContainsKey('TimeStamp') -and $TimeStamp.IsPresent) -or
            (-not $PSBoundParameters.ContainsKey('TimeStamp') -and $script:WriteMessageConfig.TimeStamp)
        ) {
            $text = ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $text)
        }

        # 3) Optional call-site context
        $includeCtx = if ($PSBoundParameters.ContainsKey('IncludeContext')) {
            $IncludeContext.IsPresent
        } else {
            $script:WriteMessageConfig.IncludeContext
        }

        if ($includeCtx) {
            $inv = $PSCmdlet.MyInvocation
            $scriptName = [IO.Path]::GetFileName($inv.ScriptName)
            $ctx = "{0}:{1}" -f $scriptName, $inv.ScriptLineNumber
            $text = "[{0}] {1}" -f $ctx, $text
        }

        # 4) JSON mode short-circuit
        $asJson = if ($PSBoundParameters.ContainsKey('AsJson')) {
            $AsJson.IsPresent
        } else {
            $script:WriteMessageConfig.AsJson
        }
        if ($asJson) {
            $entry = [PSCustomObject]@{
                TimeStamp      = (Get-Date).ToString('o')
                Level          = $Level
                Context        = if ($includeCtx) { $ctx } else { $null }
                Message        = $text
                PSComputerName = $env:COMPUTERNAME
                PSUserName     = $env:USERNAME
                ProcessId      = $PID
            }
            $entry | ConvertTo-Json -Depth 5
            return
        }

        # 5) Dispatch to streams & host
        switch ($Level) {
            'Info' {
                Write-Information -MessageData $text -InformationAction Continue
                if (
                    -not (
                        if ($PSBoundParameters.ContainsKey('NoHost')) {
                            $NoHost.IsPresent
                        } else {
                            $script:WriteMessageConfig.NoHost
                        }
                    )
                ) {
                    Write-Host $text -ForegroundColor $script:WriteMessageConfig.LevelColors.Info
                }
            }
            'Warning' { Write-Warning -Message $text }
            'Error'   { Write-Error   -Message $text }
            'Debug'   { Write-Debug   -Message $text }
        }

        # 6) File logging
        $file = if ($PSBoundParameters.ContainsKey('LogFile')) { $LogFile } else { $script:WriteMessageConfig.LogFile }
        if ($file) { Add-Content -Path $file -Value $text }
    }
}
```

### 4. Usage Examples

- Set the minimum level to Warning so Info/debug messages are ignored:

```Powershell
Write-MessageConfiguration -MinLevel Warning
```

- Enable call-site context and default file logging:

```Powershell
Write-MessageConfiguration -IncludeContext -LogFile C:\logs\app.log
```

- This Info message will now be filtered out:

```Powershell
Write-Message 'Just some detail' -Level Info
```

- This error will show, with a [MyScript.ps1:42] prefix:

```Powershell
Write-Message 'Something bad happened' -Level Error
```

### Next Up

## ✅ ANSI Escape Code Implementation Complete

The ANSI escape code support has been successfully implemented with the following features:

### Key Features Added:

1. **Bright ANSI Color Mapping**: Uses bright foreground colors for better visibility:
   - Red: 91, Green: 92, Yellow: 93, Blue: 94, Magenta: 95, Cyan: 96, Gray: 90, White: 97

2. **Automatic Terminal Detection**: Intelligently detects ANSI support based on:
   - `$Host.UI.SupportsVirtualTerminal`
   - Environment variables (`$env:TERM`, `$env:COLORTERM`)
   - Windows-specific checks for PowerShell 6+
   - Terminal window size detection

3. **Configuration Control**: Added new parameters to `Set-WriteMessageConfig`:
   - `-ForceAnsi`: Forces ANSI escape codes even if not auto-detected
   - `-DisableAnsi`: Disables ANSI and uses PowerShell native colors

4. **Graceful Fallback**: Automatically falls back to PowerShell's `Write-Host -ForegroundColor` when ANSI is not supported

5. **Cross-Platform Compatibility**: Works consistently across:
   - Windows PowerShell and PowerShell Core
   - Linux/macOS terminals
   - CI/CD environments
   - Docker containers
   - SSH sessions

### Usage Examples:

```powershell
# Auto-detect ANSI support (default)
Write-Message "Processing..." -Type Processing

# Force ANSI for CI/CD environments
Set-WriteMessageConfig -ForceAnsi
Write-Message "Success!" -Type Success

# Disable ANSI for legacy environments
Set-WriteMessageConfig -DisableAnsi
Write-Message "Warning!" -Type Warning

# Custom colors including
Set-WriteMessageConfig -LevelColors @{
    'Info' = 'Cyan'
    'Success' = 'Green'
}
```

### Test the Implementation:

Run the test script to see ANSI colors in action:
```powershell
.\test-ansi-colors.ps1
```

Let me know which other enhancements you'd like to tackle next:

- Pluggable sinks for HTTP/syslog
- Async/file batching
- Scoped correlation IDs
- Structured enrichers, performance metrics, and more!
