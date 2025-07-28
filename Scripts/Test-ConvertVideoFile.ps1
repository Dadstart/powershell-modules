[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

Write-Message 'Testing Convert-VideoFile function' -Type Info
Write-Message "Input: $InputFile" -Type Info
Write-Message "Output: $OutputFile" -Type Info

try {
    # Test the new function
    Convert-VideoFile -InputFile $InputFile -OutputFile $OutputFile -Verbose

    Write-Message 'Test completed successfully!' -Type Success
}
catch {
    Write-Message "Test failed: $($_.Exception.Message)" -Type Error
    throw
}
