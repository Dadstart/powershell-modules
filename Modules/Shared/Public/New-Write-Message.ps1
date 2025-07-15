<#
.SYNOPSIS
Outputs a formatted message to the appropriate stream (Info, Warning, Error, Debug) with optional host display,
timestamp, JSON serialization, and file logging.

.DESCRIPTION
Write-Message is a flexible and configurable logging function designed for use in scripts and modules.
It supports multiple message arguments, custom separators, timestamping, stream routing, colorized output to host,
structured JSON format, and optional logging to file.

Behavioral defaults can be customized per session or module using Write-MessageConfiguration.

.PARAMETER Message
One or more objects to output. Accepts strings, arrays, hashtables, or custom objects. Non-string objects are
converted using Out-String.

.PARAMETER Level
Specifies the message severity level. Supported values: Info, Warning, Error, Debug. Determines routing to the
appropriate PowerShell stream and optional host color.

.PARAMETER LogFile
Path to a file to which the formatted message will be appended.

.PARAMETER TimeStamp
If specified, prepends a timestamp to the message in "yyyy-MM-dd HH:mm:ss" format.

.PARAMETER Separator
Specifies the string used to separate multiple message blocks. Default is a single space (' ').

.PARAMETER NoHost
Suppresses host output (Write-Host) for Info-level messages. Stream output is still performed.

.PARAMETER AsJson
Formats the message as a structured JSON object with TimeStamp, Level, and Message properties.
Output is written only to the pipeline and not to streams or host.

.EXAMPLE
Write-Message "Started processing", $count "items." -Level Info -TimeStamp

Displays an informational message with timestamp. Output is routed to both the information stream and host.

.EXAMPLE
Write-Message "Could not locate file" -Level Warning -LogFile "C:\logs\warning.txt"

Displays a warning and appends it to the specified log file.

.EXAMPLE
Write-Message $user -AsJson

Outputs the structured message object as JSON to the pipeline without writing to host or file.

.INPUTS
System.Object[]

.OUTPUTS
System.String (via Write-Host or streams)
System.String (JSON string if -AsJson)

.NOTES
Requires [CmdletBinding()] for full support of common parameters. Honors global settings and configuration
overrides set via Write-MessageConfiguration.

.LINK
Write-MessageConfiguration
#>
function Write-Message
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
        [object[]]   $Message,

        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]     $Level = 'Info',

        [string]     $LogFile,

        [switch]     $TimeStamp,

        [string]     $Separator = ' ',

        [switch]     $NoHost,

        [switch]     $AsJson
    )

    process
    {
        # --- Resolve effective values from parameters or config ---
        $effectiveLogFile = if ($PSBoundParameters.ContainsKey('LogFile'))
        {
            $LogFile
        }
        else
        {
            $script:WriteMessageConfig.LogFile
        }
        $effectiveTimeStamp = if ($PSBoundParameters.ContainsKey('TimeStamp'))
        {
            $TimeStamp.IsPresent
        }
        else
        {
            $script:WriteMessageConfig.TimeStamp
        }
        $effectiveSep = if ($PSBoundParameters.ContainsKey('Separator'))
        {
            $Separator
        }
        else
        {
            $script:WriteMessageConfig.Separator
        }
        $effectiveNoHost = if ($PSBoundParameters.ContainsKey('NoHost'))
        {
            $NoHost.IsPresent
        }
        else
        {
            $script:WriteMessageConfig.NoHost
        }
        $effectiveAsJson = if ($PSBoundParameters.ContainsKey('AsJson'))
        {
            $AsJson.IsPresent
        }
        else
        {
            $script:WriteMessageConfig.AsJson
        }
        $effectiveColor = $script:WriteMessageConfig.LevelColors[$Level]

        # --- Format each message argument ---
        $blocks = foreach ($item in $Message)
        {
            if ($item -is [string])
            {
                $item
            }
            else
            {
                ($item | Out-String -Width ([Console]::WindowWidth)) -replace '[\r\n]+$', ''
            }
        }

        $text = $blocks -join $effectiveSep
        if ($effectiveTimeStamp)
        {
            $text = ('{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $text)
        }

        # --- Structured output mode ---
        if ($effectiveAsJson)
        {
            $entry = [PSCustomObject]@{
                TimeStamp = (Get-Date).ToString('o')
                Level     = $Level
                Message   = $text
            }
            $entry | ConvertTo-Json -Depth 5
            return
        }

        # --- Emit to appropriate stream ---
        switch ($Level)
        {
            'Info'
            {
                Write-Information -MessageData $text -InformationAction Continue
                if (-not $effectiveNoHost)
                {
                    Write-Host $text -ForegroundColor $effectiveColor
                }
            }
            'Warning'
            {
                Write-Warning -Message $text
            }
            'Error'
            {
                Write-Error -Message $text
            }
            'Debug'
            {
                Write-Debug -Message $text
            }
        }

        # --- Optional file output ---
        if ($effectiveLogFile)
        {
            Add-Content -Path $effectiveLogFile -Value $text
        }
    }
}