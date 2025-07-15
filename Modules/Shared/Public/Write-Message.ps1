function Write-Message {
    <#
    .SYNOPSIS
        Writes formatted messages with consistent styling and logging.
    
    .DESCRIPTION
        Provides a centralized way to output messages across all modules.
        Supports different message types with appropriate colors and logging.
    
    .PARAMETER Message
        The message to write.
    
    .PARAMETER Level
        The message level. Valid values are 'Info', 'Warning', 'Error', 'Success', 'Verbose', 'Debug'.
        Default is 'Info'.
    
    .PARAMETER NoNewline
        If specified, does not add a newline after the message.
    
    .PARAMETER LogToFile
        If specified, logs the message to a file in addition to console output.
    
    .EXAMPLE
        Write-Message -Message "Operation completed successfully" -Level Success
        
        Writes a green success message to the console.
    
    .EXAMPLE
        Write-Message -Message "Configuration file not found" -Level Warning
        
        Writes a yellow warning message to the console.
    
    .EXAMPLE
        Write-Message -Message "Processing file..." -Level Info -NoNewline
        
        Writes an info message without a newline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Verbose', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter()]
        [switch]$NoNewline,
        
        [Parameter()]
        [switch]$LogToFile
    )
    
    # Define colors for different message levels
    $ColorMap = @{
        'Info'    = 'White'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Success' = 'Green'
        'Verbose' = 'Cyan'
        'Debug'   = 'Gray'
    }
    
    # Get the appropriate color for the message level
    $Color = $ColorMap[$Level]
    
    # Format the message with timestamp and level
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $FormattedMessage = "[$Timestamp] [$Level] $Message"
    
    # Write to console with appropriate color
    if ($NoNewline) {
        Write-Host $FormattedMessage -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $FormattedMessage -ForegroundColor $Color
    }
    
    # Log to file if requested
    if ($LogToFile) {
        $LogPath = Join-Path $PSScriptRoot '..\..\Logs'
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        
        $LogFile = Join-Path $LogPath "PowerShellModules_$(Get-Date -Format 'yyyy-MM-dd').log"
        $FormattedMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    
    # Handle different message levels appropriately
    switch ($Level) {
        'Error' {
            # For errors, we might want to throw an exception or set error state
            $Global:LastError = $Message
        }
        'Warning' {
            # For warnings, we might want to increment a warning counter
            if (-not $Global:WarningCount) { $Global:WarningCount = 0 }
            $Global:WarningCount++
        }
    }
} 