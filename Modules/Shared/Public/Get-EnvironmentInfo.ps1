function Get-EnvironmentInfo {
<#
.SYNOPSIS
    Generate a comprehensive environment information report in Markdown format.
.DESCRIPTION
    This function collects detailed information about the current PowerShell environment including
    environment variables, PowerShell variables, loaded modules, available functions, aliases,
    PATH directories, running processes, and system services. The output is formatted as Markdown
    and saved to a file in the temp directory.
.PARAMETER OutputPath
    The path where the environment report should be saved.
.PARAMETER LaunchFile
    Switch to automatically launch the generated file after creation. Defaults to $true.
.PARAMETER Processes
    Switch to include running processes in the report. Defaults to $true.
.PARAMETER Services
    Switch to include system services in the report. Defaults to $true.
.PARAMETER Functions
    Switch to include available functions in the report. Defaults to $true.
.PARAMETER Modules
    Switch to include loaded modules in the report. Defaults to $true.
.PARAMETER Force
    Switch to overwrite existing file without prompting. Defaults to $false.
.EXAMPLE
    Get-EnvironmentInfo "C:\Reports\env.md"
    Generates an environment report and saves it to the specified path.
.EXAMPLE
    Get-EnvironmentInfo "C:\Reports\env.md"
    Generates an environment report without processes and services sections.
.NOTES
    This function requires PowerShell 5.1 or later.
    The generated report includes comprehensive system information that may be useful for
    troubleshooting, documentation, or system analysis.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$OutputPath,
        [Parameter()]
        [switch]$LaunchFile,
        [Parameter()]
        [switch]$All,
        [Parameter()]
        [switch]$Processes,
        [Parameter()]
        [switch]$Services,
        [Parameter()]
        [switch]$Functions,
        [Parameter()]
        [switch]$Modules,
        [Parameter()]
        [switch]$Force
    )
    # Check if file exists and handle Force parameter
    if (Test-Path $OutputPath) {
        if ($Force) {
            Remove-Item $OutputPath -Force
        } else {
            Write-Message "File '$OutputPath' already exists. Use -Force to overwrite." -Type Error
            return
        }
    }
    function Write-Value {
        param (
            [string]$Name,
            $Value = $null
        )
        if ($null -eq $Value) {
            Write-Output "- **$Name**: [null]"
        }
        elseif ($Value -is [array]) {
            Write-Output "- **$Name**"
            $Value | ForEach-Object {
                Write-Output "  - $_"
            }
        }
        elseif ($Value -is [hashtable]) {
            Write-Output "- **$Name**"
            $Value.GetEnumerator() | ForEach-Object {
                Write-Output "  - **$($_.Key)**: $($_.Value)"
            }
        } else {
            Write-Output "- **$Name**: $Value"
        }
    }
    # Redirect all output to the file
    & {
        Write-Output "# Environment Information Report"
        Write-Output ""
        Write-Output "*Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*"
        Write-Output ""
        Write-Output "## Environment Variables"
        Write-Output ""
        Get-ChildItem Env: -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Value $_.Name $_.Value
        }
        Write-Output ""
        Write-Output "## PowerShell Variables"
        Write-Output ""
        Get-Variable -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Value $_.Name $_.Value
        }
        Write-Output ""
        if ($Modules -or $All) {
            Write-Output "## Loaded Modules"
            Write-Output ""
            Get-Module -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Value $_.Name $_.Version
            }
            Write-Output ""
        }
        if ($Functions -or $All) {
            Write-Output "## Available Functions"
            Write-Output ""
            Get-Command -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Value $_.Name $_.CommandType
            }
            Write-Output ""
        }
        Write-Output "## Available Aliases"
        Write-Output ""
        Get-Alias -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Value $_.Name $_.Definition
        }
        Write-Output ""
        Write-Output "## PATH Directories"
        Write-Output ""
        Get-ChildItem -Path $env:PATH -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Value $_.FullName $null
        }
        Write-Output ""
        if ($Processes -or $All) {
            Write-Output "## Running Processes"
            Write-Output ""
            Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Value $_.Name "PID: $($_.Id), Memory: $([math]::Round($_.WorkingSet64/1MB, 2)) MB"
            }
            Write-Output ""
        }
        if ($Services -or $All) {
            Write-Output "## System Services"
            Write-Output ""
            Get-Service -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Value $_.Name "Status: $($_.Status), Type: $($_.ServiceType)"
            }
            Write-Output ""
        }
        Write-Output "---"
        Write-Output "*Report generated by Get-EnvironmentInfo function*"
    } | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Message "Environment information written to: $OutputPath" -Type Success
    # Launch the file if requested
    if ($LaunchFile) {
        Start-Process $OutputPath
    }
}
