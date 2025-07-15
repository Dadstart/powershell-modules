function Get-String {
    <#
    .SYNOPSIS
        Converts objects to string representation with consistent formatting.
    
    .DESCRIPTION
        Converts various PowerShell object types to string representation,
        matching the output format of Write-Host for consistency.
        
        Supported types:
        - Value types (int, double, etc.) - returns ToString()
        - Strings - returns the string if not empty
        - Hashtables/Dictionaries - returns [key, value] format
        - PSCustomObjects - returns @{property=value; property=value} format
        - Arrays - returns space-separated values
        - Collections - returns space-separated values
        - Other objects - returns ToString() result
    
    .PARAMETER Object
        The object to convert to string. Can be any PowerShell object type.
    
    .PARAMETER Separator
        The separator to use between collection elements. Defaults to space.
    
    .EXAMPLE
        Get-String 5
        Returns: "5"
    
    .EXAMPLE
        Get-String @{Name="John"; Age=30}
        Returns: "[Name, John] [Age, 30]"
    
    .EXAMPLE
        Get-String @{Name="John"; Age=30} -Separator ", "
        Returns: "[Name, John], [Age, 30]"
    
    .EXAMPLE
        Get-String [PSCustomObject]@{Name="John"; Age=30}
        Returns: "@{Name=John; Age=30}"
    
    .OUTPUTS
        [string] The string representation of the object.
    
    .NOTES
        This function is designed to produce output consistent with Write-Host
        formatting for various PowerShell object types.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments, Position = 0)]
        [AllowNull()]
        [object]$Object,

        [Parameter()]
        [object]$Separator = ' '
    )

    # Handle null input
    if ($null -eq $Object) {
        return $null
    }

    # Handle value types (int, double, bool, etc.)
    if ($Object.GetType().IsValueType) {
        return $Object.ToString()
    }

    # Handle strings
    if ($Object -is [string]) {
        if ($Object.Length -gt 0) {
            return $Object
        }
        return $null
    }

    # Handle dictionaries (hashtables, ordered dictionaries, etc.)
    if ($Object -is [System.Collections.IDictionary]) {
        $pairs = foreach ($key in $Object.Keys) {
            "[$key, $($Object[$key])]"
        }
        return $pairs -join $Separator.ToString()
    }

    # Handle PSCustomObjects
    if ($Object -is [PSCustomObject]) {
        $properties = $Object.PSObject.Properties
        $pairs = foreach ($prop in $properties) {
            "$($prop.Name)=$($prop.Value)"
        }
        return "@{$($pairs -join '; ')}"
    }

    # Handle single-element arrays
    if ($Object -is [array] -and $Object.Count -eq 1) {
        return Get-String -Object $Object[0] -Separator $Separator
    }

    # Handle other collections
    if ($Object -is [System.Collections.IEnumerable]) {
        $elements = foreach ($element in $Object) {
            Get-String -Object $element -Separator $Separator
        }
        return $elements -join $Separator.ToString()
    }

    # Handle other objects via ToString()
    $result = $Object.ToString()
    if ($result.Length -gt 0) {
        return $result
    }
    return $null
}

