function Get-MkvTracks {
    <#
    .SYNOPSIS
        Extracts multiple audio or subtitle tracks from an MKV.

    .DESCRIPTION
        This function takes an MKV, a list of track numbers and extracts them appending the specified extension.

    .PARAMETER Name
        File name of the MKV file.

    .PARAMETER Tracks
        Array of track numbers to extract.

    .PARAMETER Extension
        File extension to append to the track output.

    .EXAMPLE
        Get-MkvTracks 'Movie.mkv' (2,3) 'ac3'

        Outputs track 2 to 'Movie.2.ac3'
        Outputs track 3 to 'Movie.3.ac3'

    .INPUTS
        [string] - The MKV file name
        [int[]] - Array of track numbers to extract
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
        [int[]]$Tracks,
        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    # Check if mkvextract is installed
    Test-MkvExtractInstalled -Throw | Out-Null

    foreach ($track in $Tracks) {
        $finalExtension = "$track.$Extension"
        Get-MkvTrack $Name $track $finalExtension
    }
}