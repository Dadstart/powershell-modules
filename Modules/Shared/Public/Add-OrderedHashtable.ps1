function Add-OrderedHashtable {
    <#
    .SYNOPSIS
        Adds all entries from one ordered hashtable to the end of another ordered hashtable.

    .DESCRIPTION
        Merges two ordered hashtables by adding all key-value pairs from the source hashtable
        to the end of the target hashtable, maintaining insertion order.

    .PARAMETER TargetHashtable
        The ordered hashtable to add entries to.

    .PARAMETER SourceHashtable
        The ordered hashtable to copy entries from.

    .EXAMPLE
        $target = [ordered]@{ 'key1' = 'value1' }
        $source = [ordered]@{ 'key2' = 'value2'; 'key3' = 'value3' }
        Add-OrderedHashtable -TargetHashtable $target -SourceHashtable $source
        # Result: $target now contains key1, key2, key3 in that order
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $TargetHashtable,
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $SourceHashtable
    )

    if ($SourceHashtable) {
        foreach ($key in $SourceHashtable.Keys) {
            $TargetHashtable[$key] = $SourceHashtable[$key]
        }
    }
}