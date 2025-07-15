# PowerShell Formatting Rules and Guidelines

This document outlines the standard formatting rules and guidelines for PowerShell 7.5, following Microsoft's official recommendations and community best practices.

## Table of Contents

1. [General Principles](#general-principles)
2. [Code Structure](#code-structure)
3. [Naming Conventions](#naming-conventions)
4. [Indentation and Spacing](#indentation-and-spacing)
5. [Brace Placement](#brace-placement)
6. [Line Length and Wrapping](#line-length-and-wrapping)
7. [Comments and Documentation](#comments-and-documentation)
8. [Parameter Blocks](#parameter-blocks)
9. [Pipeline Formatting](#pipeline-formatting)
10. [Hashtable and Array Formatting](#hashtable-and-array-formatting)
11. [Error Handling](#error-handling)
12. [Performance Considerations](#performance-considerations)

## General Principles

### 1. Consistency
- Use consistent formatting throughout your codebase
- Follow established patterns within your team or organization
- Maintain readability as the primary goal

### 2. Readability
- Code should be self-documenting
- Use meaningful variable and function names
- Break complex operations into smaller, readable steps

### 3. Maintainability
- Write code that is easy to modify and extend
- Use clear structure and organization
- Minimize complexity where possible

## Code Structure

### File Organization
```powershell
# 1. Comment-based help (if applicable)
<#
.SYNOPSIS
Brief description of the script or function.

.DESCRIPTION
Detailed description of what the script or function does.

.PARAMETER ParameterName
Description of the parameter.

.EXAMPLE
Example usage of the script or function.

.NOTES
Additional notes, author, version, etc.
#>

# 2. Requires statements
#Requires -Version 7.0
#Requires -Modules PSScriptAnalyzer

# 3. Module imports
Import-Module -Name SomeModule

# 4. Variable declarations
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'config.json'

# 5. Function definitions
function Get-Something {
    # Function code
}

# 6. Main execution logic
if ($MyInvocation.InvocationName -ne '.') {
    # Script execution code
}
```

## Naming Conventions

### 1. Functions and Cmdlets
- Use **Verb-Noun** format
- Use approved PowerShell verbs
- Use singular nouns
- Use PascalCase

```powershell
# Good
function Get-UserProfile { }
function Set-Configuration { }
function Invoke-ProcessData { }

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

```powershell
# Script-scoped variables
$script:ConfigPath = 'C:\config.json'
$script:LogLevel = 'Info'

# Local variables
$userName = 'JohnDoe'
$fileCount = 0
$isValid = $true
```

### 3. Constants
- Use **UPPER_SNAKE_CASE** for constants
- Declare at the top of the script

```powershell
# Constants
$DEFAULT_TIMEOUT = 30
$MAX_RETRY_ATTEMPTS = 3
$SUPPORTED_VERSIONS = @('7.0', '7.1', '7.2', '7.3', '7.4', '7.5')
```

### 4. Parameters
- Use **PascalCase** for parameter names
- Use descriptive names
- Include parameter validation

```powershell
function Get-UserData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$MaxResults = 10
    )
}
```

## Indentation and Spacing

### 1. Basic Indentation
- Use **4 spaces** for indentation (not tabs)
- Indent consistently within code blocks

```powershell
if ($condition)
{
    Write-Host "Condition is true"
    
    if ($nestedCondition)
    {
        Write-Host "Nested condition is true"
    }
}
```

### 2. Pipeline Indentation
- Indent pipeline elements for readability
- Use consistent indentation for multi-line pipelines

```powershell
# Good - Clear pipeline structure
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5

# Also acceptable for simple pipelines
Get-Process | Where-Object { $_.CPU -gt 10 } | Sort-Object CPU
```

### 3. Assignment Alignment
- Align assignment operators for readability
- Use consistent spacing around operators

```powershell
# Good - Aligned assignments
$firstName    = 'John'
$lastName     = 'Doe'
$emailAddress = 'john.doe@example.com'
$phoneNumber  = '555-1234'

# Good - Simple assignments
$name = 'John'
$age = 30
```

## Brace Placement

### 1. Control Structures (Allman Style)
- Place opening braces on **new lines**
- Use consistent indentation

```powershell
# Good - Allman style for control structures
if ($condition)
{
    Write-Host "Condition is true"
}
else
{
    Write-Host "Condition is false"
}

foreach ($item in $items)
{
    Process-Item -InputObject $item
}

while ($condition)
{
    # Loop body
}
```

### 2. Hashtables and Arrays (Same Line)
- Place opening braces on the **same line**
- Use consistent formatting

```powershell
# Good - Hashtables
$config = @{
    ServerName = 'localhost'
    Port       = 8080
    Timeout    = 30
}

# Good - Arrays
$items = @(
    'Item1',
    'Item2',
    'Item3'
)
```

### 3. Function Definitions (Same Line)
- Place opening braces on the **same line**
- Use consistent parameter formatting

```powershell
# Good - Function definition
function Get-UserData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName
    )
    
    # Function body
}

# Good - Advanced function
function Set-Configuration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
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
```powershell
# Good - Long string broken for readability
$message = "This is a very long message that should be broken " +
           "into multiple lines for better readability and " +
           "maintainability."

# Good - Here-string for long text
$longMessage = @"
This is a very long message
that spans multiple lines
and is easy to read and maintain.
"@
```

### 3. Command Wrapping
```powershell
# Good - Long command broken into multiple lines
Get-Process |
    Where-Object { $_.ProcessName -like "*chrome*" } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 10

# Good - Long parameter list
New-Item -Path "C:\Users\$env:USERNAME\Documents\Reports" `
         -ItemType Directory `
         -Force
```

## Comments and Documentation

### 1. Comment-Based Help
- Use comment-based help for all functions
- Include all required sections
- Use proper formatting

```powershell
<#
.SYNOPSIS
    Gets user information from the system.

.DESCRIPTION
    Retrieves detailed user information including profile data,
    permissions, and account status from the local system or
    Active Directory.

.PARAMETER UserName
    The name of the user to retrieve information for.
    This parameter is mandatory and cannot be null or empty.

.PARAMETER IncludeProfile
    When specified, includes user profile information
    in the output. Default is false.

.EXAMPLE
    Get-UserInfo -UserName "JohnDoe"
    
    Retrieves basic information for user JohnDoe.

.EXAMPLE
    Get-UserInfo -UserName "JaneSmith" -IncludeProfile
    
    Retrieves detailed information including profile data
    for user JaneSmith.

.INPUTS
    System.String

.OUTPUTS
    System.Management.Automation.PSCustomObject

.NOTES
    Author: Your Name
    Version: 1.0
    Date: 2024-01-01
    
    This function requires administrative privileges for
    certain operations.

.LINK
    https://docs.microsoft.com/en-us/powershell/
#>
```

### 2. Inline Comments
- Use comments to explain complex logic
- Keep comments up to date
- Use clear, concise language

```powershell
# Calculate the average processing time
$totalTime = $endTime - $startTime
$averageTime = $totalTime / $processCount

# Skip processing if no valid items found
if ($validItems.Count -eq 0)
{
    Write-Warning "No valid items to process"
    return
}
```

### 3. TODO Comments
- Use TODO comments for future improvements
- Include context and priority

```powershell
# TODO: Implement caching mechanism for better performance
# TODO: Add support for multiple file formats
# TODO: Consider adding retry logic for network operations
```

## Parameter Blocks

### 1. Parameter Declaration
- Use proper parameter attributes
- Include validation attributes
- Use consistent formatting

```powershell
function Get-Data {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(
            Mandatory,
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

```powershell
[ValidateNotNullOrEmpty()]
[ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
[string]$EmailAddress,

[ValidateRange(1, 100)]
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

```powershell
# Good - Clear pipeline structure
$results = Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 10 |
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

```powershell
function Process-Items {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )
    
    begin {
        Write-Verbose "Starting to process items"
        $processedCount = 0
    }
    
    process {
        try
        {
            # Process each item
            $result = $InputObject | Convert-Item
            $processedCount++
            
            Write-Output $result
        }
        catch
        {
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

```powershell
# Good - Well-formatted hashtable
$config = @{
    ServerName    = 'localhost'
    Port          = 8080
    Timeout       = 30
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

```powershell
# Good - Multi-line array
$supportedVersions = @(
    '7.0',
    '7.1',
    '7.2',
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

```powershell
try
{
    $result = Invoke-RestMethod -Uri $apiUrl -Method Get
    Write-Output $result
}
catch [System.Net.WebException]
{
    Write-Error "Network error: $($_.Exception.Message)"
}
catch [System.ArgumentException]
{
    Write-Error "Invalid argument: $($_.Exception.Message)"
}
catch
{
    Write-Error "Unexpected error: $($_.Exception.Message)"
}
finally
{
    # Cleanup code
    if ($null -ne $connection)
    {
        $connection.Dispose()
    }
}
```

### 2. Error Action Preferences
- Use appropriate error action preferences
- Handle errors gracefully
- Provide fallback behavior

```powershell
# Good - Proper error handling
$items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

if ($null -eq $items)
{
    Write-Warning "No items found in path: $path"
    return
}

# Process items with error handling
foreach ($item in $items)
{
    try
    {
        Process-Item -InputObject $item
    }
    catch
    {
        Write-Warning "Failed to process item $($item.Name): $($_.Exception.Message)"
        continue
    }
}
```

## Performance Considerations

### 1. Variable Usage
- Use appropriate variable scope
- Avoid unnecessary variable creation
- Use efficient data structures

```powershell
# Good - Efficient variable usage
$results = @()
foreach ($item in $items)
{
    $results += [PSCustomObject]@{
        Name = $item.Name
        Size = $item.Length
    }
}

# Better - Use ArrayList for better performance
$results = [System.Collections.ArrayList]::new()
foreach ($item in $items)
{
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

```powershell
# Good - Efficient pipeline usage
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 |
    Export-Csv -Path 'high-cpu-processes.csv' -NoTypeInformation

# Avoid - Inefficient approach
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
