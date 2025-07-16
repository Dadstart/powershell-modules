# PowerShell Formatting Rules and Guidelines

This document outlines the standard formatting rules and guidelines for PowerShell 7.5, following Microsoft's official recommendations and community best practices.

## Table of Contents

1. [General Principles](#general-principles)
3. [Naming Conventions](#naming-conventions)
4. [Indentation and Spacing](#indentation-and-spacing)
5. [Brace Placement](#brace-placement)
6. [Line Length and Wrapping](#line-length-and-wrapping)
7. [Function Organization](#function-organization)
8. [Comments and Documentation](#comments-and-documentation)
9. [Parameter Blocks](#parameter-blocks)
10. [Pipeline Formatting](#pipeline-formatting)
11. [Hashtable and Array Formatting](#hashtable-and-array-formatting)
12. [Error Handling](#error-handling)
13. [Performance Considerations](#performance-considerations)
14. [PSScriptAnalyzer Integration](#psscriptanalyzer-integration)

## General Principles

### 1. Consistency
- Use consistent formatting throughout the codebase
- Follow established patterns
- Maintain readability as the primary goal

### 2. Readability
- Code should be self-documenting
- Use meaningful variable and function names
- Break complex operations into smaller, readable steps

### 3. Maintainability

- Write code that is easy to modify and extend
- Use clear structure and organization
- Minimize complexity where possible

## Naming Conventions

### 1. Functions and Cmdlets
- Use **Verb-Noun** format
- Use [approved PowerShell verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.5)
- Use singular nouns
- Use PascalCase

```Powershell
# Good
function Get-UserProfile { }
function Set-Configuration { }
function Invoke-ProcessData { }

####

# Bad
function getUserProfile { }
function set_configuration { }
function ProcessData { }
```

### 2. Variables
- Use **PascalCase** for script-scoped variables
- Use **camelCase** for local variables
- Use descriptive names
- Prefix script-scoped variables with `$script:`

```Powershell
# Script-scoped variables
$script:ConfigPath = 'C:\config.json'
$script:LogLevel = 'Info'

# Local variables
####

$userName = 'JohnDoe'
$fileCount = 0
$isValid = $true
```

### 3. Constants
- Use **UPPER_SNAKE_CASE** for constants
- Declare at the top of the script

```Powershell
# Constants
$DEFAULT_TIMEOUT = 30
$MAX_RETRY_ATTEMPTS = 3
$SUPPORTED_VERSIONS = @('7.4', '7.5', '7.6')
```
####


### 4. Parameters
- Use **PascalCase** for parameter names
- Use descriptive names
- Include parameter validation

```Powershell
function Get-UserData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        ####

        [string]$UserName,
        
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$MaxResults = 10
    )
}
```

## Indentation and Spacing

### 1. Basic Indentation (OTBS)
- Use **4 spaces** for indentation (not tabs)
- Indent consistently within code blocks

```Powershell
if ($condition) {
    Write-Host "Condition is true"
    
    if ($nestedCondition) {
        Write-Host "Nested condition is true"
    }
}
```

### 2. Pipeline Indentation
- Indent pipeline elements for readability
- Use consistent indentation for multi-line pipelines

```Powershell
# Good - Clear pipeline structure (strongly recommended)
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5
####


# Also acceptable for simple pipelines (less preferred)
Get-Process | Where-Object { $_.CPU -gt 10 } | Sort-Object CPU
```

### 3. Assignment Alignment
- Align assignment operators for readability
- Use consistent spacing around operators

```Powershell
# Good - Aligned assignments
$firstName    = 'John'
$lastName     = 'Doe'
$emailAddress = 'john.doe@example.com'
$phoneNumber  = '555-1234'
####


# Good - Simple assignments
$name = 'John'
$age = 30
```

## Brace Placement

### [One True Brace](https://en.wikipedia.org/wiki/Indentation_style#One_True_Brace) (OTBS)

- Place opening braces on **same line**
- Use consistent indentation

### 1. Control structures

```Powershell
if ($condition) {
    Write-Host "Condition is true"
}
else {
    Write-Host "Condition is false"
    ####

}

foreach ($item in $items) {
    Process-Item -InputObject $item
}

while ($condition) {
    # Loop body
}
```

### 2. Hashtables and Arrays

#### Preferred

```Powershell
$config = @{
    ServerName = 'localhost'
    Port       = 8080
    Timeout    = 30
}
    ####


$items = @(
    'Item1',
    'Item2',
    'Item3'
)
```

#### Acceptable for short definition

```Powershell
$config = @{ ServerName = 'localhost' }
$items = @('Item1', 'Item2')
```

### 3. Function definition


```Powershell
function Get-UserData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName
        ####

    )
    
    # Function body
}
```

### 4. Advanced Function

```Powershell
function Set-Configuration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        ####

        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        # Initialization code
    }
    
    process {
        # Main processing logic
    }
    
    end {
        # Cleanup code
    }
}
```

## Line Length and Wrapping

### 1. Maximum Line Length

- Keep lines under **120 characters** when possible
- Break long lines for readability

### 2. String Wrapping

#### Long string broken for readability that keeps indentation

```Powershell
$message = "This is a very long message that should be broken " +
           "into multiple lines for better readability and " +
           "maintainability."
```

#### Use Here-string for long text that ignores line wrapping

```Powershell
$longMessage = @"
This is a very long message
that spans multiple lines
and is easy to read and maintain.
"@
```

### 3. Command Wrapping

#### Long command broken into multiple lines

```Powershell
Get-Process |
    Where-Object { $_.ProcessName -like "*chrome*" } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 10
####
```

#### Long parameter list

```Powershell
New-Item -Path "C:\Users\$env:USERNAME\Documents\Reports" `
         -ItemType Directory `
         -Force
```

## Function Organization

- Use comment-based help for all functions
- Include all required sections
- Use proper formatting

### 1. Function documentation

```Powershell
<#
.SYNOPSIS
    Retrieves user data from the system.

.DESCRIPTION
    The Get-UserData cmdlet retrieves detailed information about users in the system.
    It supports filtering by various criteria and can return different levels of detail.

.PARAMETER UserName
    The name of the user to retrieve information for. This parameter is mandatory.

.PARAMETER MaxResults
    The maximum number of results to return. Default is 10, maximum is 100.

.PARAMETER DetailLevel
    The level of detail to include in the results. Valid values are 'Basic', 'Detailed', and 'Full'.
    Default is 'Basic'.

.PARAMETER IncludeMetadata
    When specified, includes additional metadata in the results.

.EXAMPLE
    Get-UserData -UserName "JohnDoe"
    
    Retrieves basic information for user "JohnDoe".

.EXAMPLE
    Get-UserData -UserName "JaneSmith" -DetailLevel "Full" -IncludeMetadata
    
    Retrieves full detailed information including metadata for user "JaneSmith".

.INPUTS
    None. You cannot pipe objects to Get-UserData.

.OUTPUTS
    PSCustomObject. Returns user information objects.

.NOTES
    This cmdlet requires appropriate permissions to access user data.
    For large datasets, consider using the MaxResults parameter to limit output.

.LINK
    https://docs.microsoft.com/en-us/powershell/module/example/get-userdata
#>
```

### 2. Requires statements (recommended)

```Powershell
#Requires -Version 7.4
#Requires -Modules PSScriptAnalyzer
```

### 3. Module imports (less desired, shared functions are handled differently)


```Powershell
Import-Module -Name SomeModule
```

### 4. Variable declarations (less desired, prefer local variables within each function)


```Powershell
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'config.json'
```

### 5. Function definitions


```Powershell
function Get-Something {
    # Function code
}
```

### 6. Main execution logic

```Powershell
if ($MyInvocation.InvocationName -ne '.') {
    # Script execution code
}
```

## Comments and Documentation

### 1. Block Comments

- Use block comments to wrap code blocks
- Place comment delimiters <# and #> on separate lines
- Use consistent indentation

```Powershell
<#
Note: We previously did this:
$foo | For-Each { Delete-Foo $_}

Not anymore, because...
####

#>
```

### 2. Inline Comments

- Use comments to explain complex logic
- Keep comments up to date
- Use clear, concise language
- **Prefer:** Place inline comments on separate lines

```Powershell
# Calculate the average processing time
$totalTime = $endTime - $startTime
$averageTime = $totalTime / $processCount

# Skip processing if no valid items found
if ($validItems.Count -eq 0) {
    Write-Warning "No valid items to process"
    return
}
```

### 3. TODO Comments

- Use TODO comments for future improvements
- Include context and priority

```Powershell
# TODO: Implement caching mechanism for better performance
# TODO: Add support for multiple file formats
# TODO: Consider adding retry logic for network operations
```

####

## Parameter Blocks

### 1. Parameter Declaration

- Use proper parameter attributes
- Don't use `= $true` for Switch parameters
- Include validation attributes
- Use consistent formatting

```Powershell
function Get-Data {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(
            Mandatory,
            ####

            ParameterSetName = 'ByName',
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Enter the name of the item to retrieve'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9_-]+$')]
        [string]$Name,
        
        [Parameter(
            Mandatory,
            ParameterSetName = 'ById',
            Position = 0
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Id,
        
        [Parameter()]
        [ValidateSet('Basic', 'Detailed', 'Full')]
        [string]$DetailLevel = 'Basic',
        
        [Parameter()]
        [switch]$IncludeMetadata,
        
        [Parameter()]
        [ValidateNotNull()]
        [hashtable]$Options = @{}
    )
}
```

### 2. Parameter Validation

- Use appropriate validation attributes
- Provide meaningful error messages
- Validate input early

```Powershell
[ValidateNotNullOrEmpty()]
[ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
[string]$EmailAddress,

[ValidateRange(1, 100)]
####

[int]$MaxResults,

[ValidateScript({
    if (Test-Path -Path $_ -PathType Leaf) { $true }
    else { throw "File not found: $_" }
})]
[string]$ConfigFile
```

## Pipeline Formatting

### 1. Pipeline Structure

- Use consistent indentation
- Break long pipelines for readability
- Use meaningful variable names

```Powershell
# Good - Clear pipeline structure
$results = Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 10 |
####

    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.ProcessName
            CPU  = $_.CPU
            Memory = $_.WorkingSet
        }
    }
```

### 2. Pipeline Functions

- Use proper pipeline support
- Implement all pipeline blocks when needed

```Powershell
function Process-Items {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
        ####

    )
    
    begin {
        Write-Verbose "Starting to process items"
        $processedCount = 0
    }
    
    process {
        try {
            # Process each item
            $result = $InputObject | Convert-Item
            $processedCount++
            
            Write-Output $result
        }
        catch {
            Write-Error "Failed to process item: $($_.Exception.Message)"
        }
    }
    
    end {
        Write-Verbose "Processed $processedCount items"
    }
}
```

## Hashtable and Array Formatting

### 1. Hashtable Formatting

- Use consistent key-value alignment
- Use proper spacing and indentation
- Use meaningful key names

```Powershell
# Good - Well-formatted hashtable
$config = @{
    ServerName    = 'localhost'
    Port          = 8080
    Timeout       = 30
    ####

    RetryAttempts = 3
    LogLevel      = 'Info'
}

# Good - Nested hashtables
$settings = @{
    Database = @{
        Server   = 'sqlserver.local'
        Database = 'MyApp'
        Timeout  = 60
    }
    Logging = @{
        Level = 'Info'
        Path  = 'C:\Logs'
    }
}
```

### 2. Array Formatting

- Use consistent formatting for multi-line arrays
- Use proper indentation
- Use meaningful element names

```Powershell
# Good - Multi-line array
$supportedVersions = @(
    '7.0',
    '7.1',
    '7.2',
    ####

    '7.3',
    '7.4',
    '7.5'
)

# Good - Array of objects
$users = @(
    [PSCustomObject]@{
        Name  = 'John Doe'
        Email = 'john.doe@example.com'
        Role  = 'Admin'
    },
    [PSCustomObject]@{
        Name  = 'Jane Smith'
        Email = 'jane.smith@example.com'
        Role  = 'User'
    }
)
```

## Error Handling

### 1. Try-Catch Blocks

- Use proper error handling
- Use specific exception types when possible
- Provide meaningful error messages

```Powershell
try {
    $result = Invoke-RestMethod -Uri $apiUrl -Method Get
    Write-Output $result
}
catch [System.Net.WebException] {
    Write-Error "Network error: $($_.Exception.Message)"
}
catch [System.ArgumentException] {
    Write-Error "Invalid argument: $($_.Exception.Message)"
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
}
finally {
    # Cleanup code
    if ($null -ne $connection) {
        $connection.Dispose()
    }
}
```

### 2. Error Action Preferences

- Use appropriate error action preferences
- Handle errors gracefully
- Provide fallback behavior

```Powershell
# Good - Proper error handling
$items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

if ($null -eq $items) {
    Write-Warning "No items found in path: $path"
    return
}

# Process items with error handling
foreach ($item in $items) {
    try {
        Process-Item -InputObject $item
    }
    catch {
        Write-Warning "Failed to process item $($item.Name): $($_.Exception.Message)"
        continue
    }
}
```

## Performance Considerations

### 1. Variable Usage

- Use appropriate variable scope
- Avoid unnecessary variable creation, except for long definitions or too much nested code on the same line
- Use efficient data structures

#### Good - Efficient variable usage
```Powershell
# Good - Efficient variable usage
$results = @()
foreach ($item in $items) {
    $results += [PSCustomObject]@{
        Name = $item.Name
        Size = $item.Length
    }
}
```

#### Better - Use ArrayList for better performance

```Powershell
$results = [System.Collections.ArrayList]::new()
foreach ($item in $items) {
    $null = $results.Add([PSCustomObject]@{
        Name = $item.Name
        Size = $item.Length
    })
}
```

### 2. Pipeline Usage

- Use pipelines for data processing
- Avoid unnecessary intermediate variables
- Use appropriate cmdlets

#### Good - Efficient pipeline usage

```Powershell
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 |

    Export-Csv -Path 'high-cpu-processes.csv' -NoTypeInformation
```

#### Avoid - Inefficient approach

```Powershell
$processes = Get-Process
$filtered = $processes | Where-Object { $_.CPU -gt 10 }
$sorted = $filtered | Sort-Object -Property CPU -Descending
$top5 = $sorted | Select-Object -First 5
$top5 | Export-Csv -Path 'high-cpu-processes.csv' -NoTypeInformation
```

## PSScriptAnalyzer Integration

### 1. Configuration

- Use PSScriptAnalyzer to enforce formatting rules
- Configure rules according to your standards
- Run analysis regularly

### 2. Common Rules

- `PSPlaceOpenBraceOnNewLine` - Enforce Allman style for control structures
- `PSUseConsistentIndentation` - Enforce consistent indentation
- `PSAvoidLongLines` - Limit line length
- `PSAvoidTrailingWhitespace` - Remove trailing whitespace
- `PSUseConsistentWhitespace` - Enforce consistent spacing

## Summary

Following these formatting guidelines will help ensure:

- **Consistency** across your PowerShell codebase
- **Readability** for you and your team
- **Maintainability** for future development
- **Compliance** with PowerShell best practices
- **Professional** code quality

Remember that these guidelines are meant to improve code quality and team collaboration. Adapt them to your specific needs while maintaining consistency within your organization.
