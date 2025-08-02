function Add-HashtableArgs {
    <#
    .SYNOPSIS
        Adds arguments from a hashtable to the final arguments list.

    .DESCRIPTION
        Processes a hashtable of arguments and adds them to the final arguments list.
        If a hashtable entry has both a key and value, both are added to the argument list.
        If a hashtable entry has only a key (value is $null), just the key is added to the argument list.

    .PARAMETER FinalArgs
        The final arguments list to add the arguments to.

    .PARAMETER AdditionalArgs
        The hashtable containing arguments to add.

    .EXAMPLE
        $finalArgs = New-Object System.Collections.Generic.List[string]
        $additionalArgs = @{
            '-metadata' = 'title=My Video'
            '-an' = $null
        }
        Add-HashtableArgs -FinalArgs $finalArgs -AdditionalArgs $additionalArgs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[string]] $FinalArgs,
        [Parameter()]
        [hashtable] $AdditionalArgs
    )

    if ($AdditionalArgs) {
        foreach ($key in $AdditionalArgs.Keys) {
            $value = $AdditionalArgs[$key]
            if ($null -eq $value) {
                # Key only - add just the key
                $FinalArgs.Add($key)
            } else {
                # Key and value - add both
                $FinalArgs.Add($key)
                $FinalArgs.Add($value)
            }
        }
    }
} 