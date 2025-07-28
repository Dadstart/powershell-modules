[CmdletBinding()]
param (
    [Parameter()]
    [string]$InputFile,
    [Parameter()]
    [string]$OutputFile
)

# Import the NewMediaTools module
Import-Module "$PSScriptRoot\..\Modules\NewMedia\NewMediaTools" -Force

$InputFile = Get-Path $InputFile -PathType Absolute -ValidatePath File
$OutputFile = Get-Path $OutputFile -PathType Absolute

Write-Message "Using Convert-VideoFile function for conversion" -Type Info

# Use the new Convert-VideoFile function
Convert-VideoFile -InputFile $InputFile.FullName -OutputFile $OutputFile.FullName -Verbose
