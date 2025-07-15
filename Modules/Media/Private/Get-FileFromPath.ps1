function Get-FileFromPath {
    <#
    .SYNOPSIS
        Checks if a file is available in the current environment paths.

    .DESCRIPTION
        This function checks if the file exists in the system PATH and returns the file information if it does.

    .PARAMETER Name
        The file name to check.

    .EXAMPLE
        Get-FileFromPath -Name 'explorer'

        Returns an [ApplicationInfo] for 'explorer.exe'.

    .EXAMPLE
        Get-FileFromPath -Name 'bogusfile'

        Returns $null if 'bogusfile' does not exist in the current environment paths.

    .OUTPUTS
        [System.Management.Automation.ApplicationInfo]
        Returns an object containing the properties including Name and Path, or $null if not found.

    .NOTES
        This is an internal helper function used by other module functions.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ApplicationInfo])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $cmd = Get-Command -Name $Name -ErrorAction SilentlyContinue -CommandType Application -TotalCount 1
    return $cmd
}