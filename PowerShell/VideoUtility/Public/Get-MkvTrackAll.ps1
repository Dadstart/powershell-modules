function Get-MkvTrackAll {
    <#
    .SYNOPSIS
        Extracts an audio or subtitle track from multiple files.

    .DESCRIPTION
        This function takes list of MKV files, a track number and extracts them appending the specified extension.

    .PARAMETER Names
        File names of the MKV files.

    .PARAMETER Track
        Track number to extract.

    .PARAMETER Extension
        File extension to append to the track outputs.

    .EXAMPLE
        Get-MkvTrackAll ('Movie.mkv','Film.mkv') 2 'en.sdh.sup'

        Outputs track 2 from 'Movie.mkv' to 'Movie.en.sdh.sup'
        Outputs track 2 from 'Film.mkv' to 'Film.en.sdh.sup'

    .INPUTS
        [string[]] - Array of MKV file names
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
        [string[]]$Names,
        [Parameter(Mandatory = $true)]
        [int]$Track,
        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    # Check if mkvextract is installed
    Test-MkvExtractInstalled -Throw | Out-Null

    foreach ($name in $Names) {
        Get-MkvTrack "$name" $Track $Extension
    }
}