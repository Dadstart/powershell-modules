function Set-DefaultParameters {
    <#
    .SYNOPSIS
        Sets default parameter values for verbose and debug preferences across called functions.
    
    .DESCRIPTION
        Centralizes the common pattern of passing verbose and debug preferences to called functions.
        This reduces code duplication and ensures consistent parameter handling across the module.
    
    .EXAMPLE
        Set-DefaultParameters
        
        Sets the default parameters for the current session's verbose and debug preferences.
    #>
    [CmdletBinding()]
    param()
    
    $PSDefaultParameterValues['Convert-VideoFiles:Verbose'] = $VerbosePreference
    $PSDefaultParameterValues['Convert-VideoFiles:Debug'] = $DebugPreference
    $PSDefaultParameterValues['Get-MediaStreams:Verbose'] = $VerbosePreference
    $PSDefaultParameterValues['Get-MediaStreams:Debug'] = $DebugPreference
    $PSDefaultParameterValues['Invoke-FFmpeg:Verbose'] = $VerbosePreference
    $PSDefaultParameterValues['Invoke-FFmpeg:Debug'] = $DebugPreference
    $PSDefaultParameterValues['Invoke-Process:Verbose'] = $VerbosePreference
    $PSDefaultParameterValues['Invoke-Process:Debug'] = $DebugPreference
    $PSDefaultParameterValues['Write-Message:Verbose'] = $VerbosePreference
    $PSDefaultParameterValues['Write-Message:Debug'] = $DebugPreference
} 
