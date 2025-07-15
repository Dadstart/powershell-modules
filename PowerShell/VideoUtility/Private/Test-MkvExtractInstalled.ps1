function Test-MkvExtractInstalled {
    <#
    .SYNOPSIS
        Checks if mkvextract is installed on the system.

    .DESCRIPTION
        This function checks if mkvextract is available in the system's PATH.
        It returns $true if mkvextract is found, otherwise it returns $false.

    .PARAMETER Throw
        Throw if mkvextract is not installed.

    .EXAMPLE
        Test-MkvExtractInstalled

        Returns $true if mkvextract is installed, otherwise $false.

    .EXAMPLE
        Test-MkvExtractInstalled -Throw

        Returns $true if mkvextract is installed, otherwise throws an error.

    .OUTPUTS
        [boolean]
        Returns $true if mkvextract is found, otherwise $false.

    .NOTES
        This is an internal helper function used by other module functions.
    #>
    [CmdletBinding()]
    [OutputType([boolean])]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Throw
    )

    $test = Get-FileFromPath -Name 'mkvextract'

    if ($null -ne $test) {
        return $true
    }
    elseif ($Throw) {
        throw "mkvextract is not installed or in the system PATH."
    }
    else {
        return $false
    }
}