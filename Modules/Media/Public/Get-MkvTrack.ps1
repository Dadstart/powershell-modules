function Get-MkvTrack {
    <#
    .SYNOPSIS
        Extracts an audio or subtitle track from an MKV.

    .DESCRIPTION
        This function takes an MKV, track number and extracts it appending the specified extension.

    .PARAMETER Name
        File name of the MKV file.

    .PARAMETER Track
        Track number to extract.

    .PARAMETER Extension
        File extension to append to the track output.

    .EXAMPLE
        Get-MkvTrack 'Movie.mkv' 2 'en.sdh.sup'

        Outputs track 2 to 'Movie.en.sdh.sup'

    .INPUTS
        [string] - The MKV file name
        [int] - The track number to extract
        [string] - The file extension to append

    .OUTPUTS
        None. Creates files in the current directory.

    .NOTES
        This function requires mkvextract to be installed and available in the system PATH.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [int]$Track,
        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    # Check if mkvextract is installed
    Test-MkvExtractInstalled -Throw | Out-Null

    # Remove .mkv extension if present
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Name)

    Write-Information "Extracting track $Track from '$Name'" -InformationAction Continue

    $outputName = Join-Path -Path (Get-Location) -ChildPath "$baseName.$Extension"
    mkvextract "$Name" tracks $Track`:"$outputName"

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to extract track (Exit code: $LASTEXITCODE)"
    }
    else {
        Write-Information 'Complete' -InformationAction Continue
    }
}