function Find-StringInFiles {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Searches for a string pattern in files within a specified directory.
    .DESCRIPTION
        This function searches for a specified string pattern in files matching the given
        include patterns. It can search recursively through subdirectories and optionally
        display the matching lines with highlighted search terms.
    .PARAMETER SearchString
        The string pattern to search for in the files. This parameter is mandatory.
    .PARAMETER Path
        The directory path to search in. Defaults to the current directory (".").
    .PARAMETER Include
        An array of file patterns to include in the search. Defaults to "*.ps1".
        Examples: "*.txt", "*.ps1", "*.md"
    .PARAMETER ShowMatches
        When specified, displays the actual matching lines with highlighted search terms.
    .EXAMPLE
        Find-StringInFiles -SearchString "Get-ChildItem"
        Searches for "Get-ChildItem" in all PowerShell files in the current directory.
    .EXAMPLE
        Find-StringInFiles -SearchString "function" -Path "C:\Scripts" -Include "*.ps1", "*.psm1"
        Searches for "function" in PowerShell files in the C:\Scripts directory.
    .EXAMPLE
        Find-StringInFiles -SearchString "error" -ShowMatches
        Searches for "error" in PowerShell files and displays the matching lines with highlighting.
    .EXAMPLE
        Find-StringInFiles -SearchString "TODO" -Path "C:\Project" -Include "*.md", "*.txt"
        Searches for "TODO" in markdown and text files in the C:\Project directory.
    .OUTPUTS
        [Microsoft.PowerShell.Commands.MatchInfo[]] - Array of match information objects containing:
        - Path: Full path to the file containing the match
        - LineNumber: Line number where the match was found
        - Line: The complete line containing the match
        - Matches: Collection of match objects
    .NOTES
        This function uses Select-String internally and supports all the same search capabilities.
        The search is case-sensitive by default. Use regex patterns for more complex searches.
    .LINK
        Select-String
        Get-ChildItem
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Path = ".",
        [Parameter()]
        [string[]]$Include = "*.ps1",
        [Parameter()]
        [switch]$ShowMatches
    )
    try {
        Write-Message "Searching for files matching patterns: $($Include -join ', ')" -Type Verbose
        $files = Get-ChildItem -Path $Path -Include $Include -Recurse
        Write-Message "Found $($files.Count) files to search" -Type Verbose
        Write-Message "Searching for string: '$SearchString'" -Type Verbose
        $results = Select-String -Path $files -Pattern $SearchString
        Write-Message "Found $($results.Count) matches" -Type Verbose
        foreach ($result in $results) {
            Write-Message "Processing match in file: $($result.Path), line: $($result.LineNumber)" -Type Verbose
            $line = $result.Line
            $match = $result.Matches[0].Value
            Write-Message "$($result.Path):$($result.LineNumber)" -Type Verbose
            if ($ShowMatches) {
                Write-Message "Showing highlighted match" -Type Verbose
                $highlighted = $line -replace [regex]::Escape($match), "`e[93m$match`e[0m"
                Write-Message "  $highlighted" -Type Verbose
            }
        }
        return $results
    }
    catch {
        Write-Message "Find-StringInFiles function failed with error: $($_.Exception.Message)" -Type Verbose
        Write-Message "String search failed: $($_.Exception.Message)" -Type Error
        throw "String search failed: $($_.Exception.Message)"
    }
}
