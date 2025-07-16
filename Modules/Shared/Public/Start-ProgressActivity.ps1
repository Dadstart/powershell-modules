function Start-ProgressActivity {
    <#
    .SYNOPSIS
        Starts a new progress operation and returns a ProgressActivity instance.
    .DESCRIPTION
        Wrapper function for ProgressActivity::Start that provides better parameter handling
        and default values. This function is the recommended way to create progress activities
        across all modules.
    .PARAMETER Activity
        A descriptive name for the operation being performed.
        Used in the progress bar title.
    .PARAMETER Status
        Initial status message to display. Can be updated during execution.
        Default is "Processing..."
    .PARAMETER TotalItems
        Total number of items to process. Used for percentage calculation.
        If not specified, progress bar shows indeterminate progress.
    .PARAMETER CurrentItem
        Current item number being processed. Used for percentage calculation.
        Should be updated during execution if TotalItems is specified.
    .PARAMETER PercentComplete
        Explicit percentage complete (0-100). Overrides TotalItems/CurrentItem calculation.
    .PARAMETER SecondsRemaining
        Estimated seconds remaining for the operation.
    .PARAMETER Id
        Unique identifier for the progress bar. Default is 1.
        Use different IDs for nested progress operations.
    .PARAMETER ParentId
        ID of the parent progress bar for nested operations.
    .EXAMPLE
        $progress = Start-ProgressActivity -Activity "Processing files" -TotalItems 10
        foreach ($file in $files) {
            $progress.Update(@{ CurrentItem = $i; Status = "Processing $file" })
            Start-Sleep -Seconds 1
        }
        $progress.Stop(@{ Status = "All files processed" })
    .EXAMPLE
        $progress = Start-ProgressActivity -Activity "Downloading" -Status "Starting download..."
        try {
            # ... download operation ...
            $progress.Stop(@{ Status = "Download completed successfully" })
        }
        catch {
            $progress.Stop(@{ Status = $_.Exception.Message; IsError = $true })
            throw
        }
    .OUTPUTS
        A ProgressActivity instance that can be used to update and stop progress.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Activity,
        [string]$Status = 'Processing...',
        [int]$TotalItems = 0,
        [int]$CurrentItem = 0,
        [int]$PercentComplete = -1,
        [int]$SecondsRemaining = -1,
        [int]$Id = 1,
        [int]$ParentId = -1
    )
    $arguments = @{
        Activity         = $Activity
        Status           = $Status
        TotalItems       = $TotalItems
        CurrentItem      = $CurrentItem
        PercentComplete  = $PercentComplete
        SecondsRemaining = $SecondsRemaining
        Id               = $Id
        ParentId         = $ParentId
    }
    $progress = [ProgressActivity]::Start($arguments)
    return $progress
}
