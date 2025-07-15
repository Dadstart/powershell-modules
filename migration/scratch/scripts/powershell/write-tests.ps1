param(
    [object]$obj
)
$original = [System.Console]::Out

# Create a StringWriter to capture output
$sw = New-Object System.IO.StringWriter
$tw = New-Object System.Diagnostics.TextWriterTraceListener($sw)
[System.Diagnostics.Trace]::Listeners.Add($tw)

# Redirect output
[Console]::SetOut($sw)

# Flush and retrieve content
[System.Diagnostics.Trace]::Flush()
$captured = $sw.ToString()

# Restore console output
[Console]::SetOut($original)


Write-Host
Write-Host '#### $obj'
Write-Host
Write-Host '```PowerShell'
$obj | Out-String | Write-Host
Write-Host '```'
Write-Host

Write-Host '#### $obj.ToString()'
Write-Host
Write-Host '```PowerShell'
$obj.ToString() | Out-String | Write-Host
Write-Host '```'
Write-Host

Write-Host '#### Write-Host $obj'
Write-Host
Write-Host '```PowerShell'
Write-Host $obj | Out-String | Write-Host
Write-Host '```'
Write-Host

Write-Host '#### [object]$obj'
Write-Host
Write-Host '```PowerShell'
[object]$obj | Out-String | Write-Host
Write-Host '```'
Write-Host

Write-Host '#### ([object]$obj).ToString()'
Write-Host
Write-Host '```PowerShell'
([object]$obj).ToString() | Out-String | Write-Host
Write-Host '```'
Write-Host

$captured | Set-Clipboard
