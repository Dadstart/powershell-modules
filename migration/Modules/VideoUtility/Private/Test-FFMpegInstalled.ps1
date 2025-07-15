function Test-FFMpegInstalled {
    <#
    .SYNOPSIS
        Checks if ffmpeg is installed on the system.

    .DESCRIPTION
        This function checks if ffmpeg is available in the system's PATH.
        It returns $true if ffmpeg is found, otherwise it returns $false.

    .PARAMETER Throw
        Throw if ffmpeg is not installed.

    .EXAMPLE
        Test-FFMpegInstalled

        Returns $true if ffmpeg is installed, otherwise $false.

    .EXAMPLE
        Test-FFMpegInstalled -Throw $true

        Returns $true if ffmpeg is installed, otherwise throws an error.

    .OUTPUTS
        [boolean]
        Returns $true if ffmpeg is found, otherwise $false.

    .NOTES
        This is an internal helper function used by other module functions.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Throw
    )

    $test = Get-FileFromPath -Name 'ffmpeg'

    if ($null -ne $test) {
        return $true
    }
    elseif ($Throw) {
        throw "ffmpeg is not installed or in the system PATH."
    }
    else {
        return $false
    }
}