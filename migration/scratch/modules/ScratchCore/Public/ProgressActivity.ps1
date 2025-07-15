class ProgressActivity {
    <#
    .SYNOPSIS
        Represents a progress operation with methods for updating and stopping progress.
    
    .DESCRIPTION
        ProgressActivity encapsulates a progress operation started with Write-Progress.
        It provides methods to update progress information and stop the operation.
        This class provides a cleaner, more object-oriented approach to progress reporting.
    
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
    #>
    
    # Private members
    hidden [string]$Activity
    hidden [string]$Status
    hidden [int]$TotalItems
    hidden [int]$CurrentItem
    hidden [int]$PercentComplete
    hidden [int]$SecondsRemaining
    hidden [int]$Id
    hidden [int]$ParentId
    hidden [bool]$IsCompleted
    
    # Constructor (private - use static Start method)
    hidden ProgressActivity([hashtable]$inputParams) {
        $this.Activity = $inputParams.Activity ?? ''
        $this.Status = $inputParams.Status ?? 'Processing...'
        $this.TotalItems = $inputParams.TotalItems ?? 0
        $this.CurrentItem = $inputParams.CurrentItem ?? 0
        $this.PercentComplete = $inputParams.PercentComplete ?? -1
        $this.SecondsRemaining = $inputParams.SecondsRemaining ?? -1
        $this.Id = $inputParams.Id ?? 1
        $this.ParentId = $inputParams.ParentId ?? -1
        $this.IsCompleted = $false
        
        # Start the progress bar
        $this._UpdateProgressBar()
    }
    
    <#
    .SYNOPSIS
        Starts a new progress operation and returns a ProgressActivity instance.
    
    .DESCRIPTION
        Static method that creates and starts a new progress operation.
        This is the primary way to create a ProgressActivity instance.
        Uses a hashtable parameter pattern for consistency with other methods.
        All parameters except Activity are optional.
    
    .PARAMETER Args
        A hashtable containing the parameters for starting. Valid keys are:
        - Activity: A descriptive name for the operation being performed. Used in the progress bar title.
        - Status: Initial status message to display. Can be updated during execution. Default is "Processing..."
        - TotalItems: Total number of items to process. Used for percentage calculation. If not specified, progress bar shows indeterminate progress.
        - CurrentItem: Current item number being processed. Used for percentage calculation. Should be updated during execution if TotalItems is specified.
        - PercentComplete: Explicit percentage complete (0-100). Overrides TotalItems/CurrentItem calculation.
        - SecondsRemaining: Estimated seconds remaining for the operation.
        - Id: Unique identifier for the progress bar. Default is 1. Use different IDs for nested progress operations.
        - ParentId: ID of the parent progress bar for nested operations.
    
    .EXAMPLE
        $progress = [ProgressActivity]::Start(@{ Activity = "Processing files"; Status = "Starting..."; TotalItems = 10 })
        foreach ($file in $files) {
            $progress.Update(@{ CurrentItem = $i; Status = "Processing $file" })
            Start-Sleep -Seconds 1
        }
        $progress.Stop(@{ Status = "All files processed" })
        
    .EXAMPLE
        # Simple start with just activity
        $progress = [ProgressActivity]::Start(@{ Activity = "Downloading" })
        
        # Start with multiple parameters
        $progress = [ProgressActivity]::Start(@{ 
            Activity = "Complex operation"; 
            Status = "Starting..."; 
            TotalItems = 100;
            Id = 2;
            ParentId = 1
        })
        
    .OUTPUTS
        A ProgressActivity instance that can be used to update and stop progress.
    #>
    static [ProgressActivity] Start([hashtable]$inputParams = @{}) {
        return [ProgressActivity]::new($inputParams)
    }
    
    <#
    .SYNOPSIS
        Updates the progress bar with new information.
    
    .DESCRIPTION
        Updates the progress bar with new status, current item, percentage, or time remaining.
        Only the parameters you want to update need to be specified in the hashtable.
    
    .PARAMETER Args
        A hashtable containing the parameters to update. Valid keys are:
        - CurrentItem: New current item number. If not specified, keeps the current value.
        - Status: New status message to display. If not specified, keeps the current status.
        - PercentComplete: New percentage complete (0-100). Overrides TotalItems/CurrentItem calculation.
        - SecondsRemaining: New estimated seconds remaining for the operation.
    
    .EXAMPLE
        $progress = Start-ProgressActivity -Activity "Processing files" -Status "Starting..." -TotalItems 10
        $progress.Update(@{ CurrentItem = 1; Status = "Processing file1.txt" })
        $progress.Update(@{ CurrentItem = 2; Status = "Processing file2.txt" })
        $progress.Update(@{ CurrentItem = 3; Status = "Processing file3.txt" })
        $progress.Stop("All files processed")
        
    .EXAMPLE
        $progress = Start-ProgressActivity -Activity "Downloading" -Status "Starting download..."
        $progress.Update(@{ Status = "Halfway done!"; PercentComplete = 50 })
        $progress.Update(@{ Status = "Almost done!"; PercentComplete = 90 })
        $progress.Stop("Download completed")
        
    .EXAMPLE
        $progress = Start-ProgressActivity -Activity "Complex operation" -Status "Starting..." -TotalItems 100
        
        # Update only current item
        $progress.Update(@{ CurrentItem = 25 })
        
        # Update only status
        $progress.Update(@{ Status = "Processing phase 2" })
        
        # Update only percentage
        $progress.Update(@{ PercentComplete = 75 })
        
        # Update only time remaining
        $progress.Update(@{ SecondsRemaining = 30 })
        
        # Update multiple parameters at once
        $progress.Update(@{ CurrentItem = 90; Status = "Final phase"; PercentComplete = 90; SecondsRemaining = 5 })
        
        $progress.Stop(@{ Status = "Operation completed" })
    #>
    
    [void] Update([hashtable]$inputParams) {
        if ($this.IsCompleted) {
            throw 'Cannot update a completed progress activity'
        }

        # Ensure Args is a hashtable
        if ($inputParams -isnot [hashtable]) {
            throw 'Update method requires a hashtable parameter'
        }

        # Update the progress context
        #        $newStatus = if ($inputParams.ContainsKey('Status')) { $inputParams['Status'] } else { 'Completed' }
        $newCurrentItem = $inputParams.CurrentItem ?? -1
        $newStatus = $inputParams.Status ?? ''
        $newPercentComplete = $inputParams.PercentComplete ?? -1
        $newSecondsRemaining = $inputParams.SecondsRemaining ?? -1

        if ($newCurrentItem -and ($newCurrentItem -ge 0)) {
            $this.CurrentItem = $newCurrentItem
        }

        if ($newStatus) {
            $this.Status = $newStatus
        }
        
        if ($newPercentComplete -and ($newPercentComplete -ge 0)) {
            $this.PercentComplete = $newPercentComplete
        }
        
        if ($newSecondsRemaining -and ($newSecondsRemaining -ge 0)) {
            $this.SecondsRemaining = $newSecondsRemaining
        }
        
        # Update the progress bar
        $this._UpdateProgressBar()
    }
    
    <#
    .SYNOPSIS
        Stops the progress operation and removes the progress bar.
    
    .DESCRIPTION
        Stops the progress operation and displays a final status message.
        The progress bar is removed from the display after this call.
        Uses a hashtable parameter pattern for consistency with other methods.
    
    .PARAMETER Args
        A hashtable containing the parameters for stopping. Valid keys are:
        - Status: Final status message to display before stopping. Default is "Completed".
        - IsError: If true, displays the status as an error message. Default is false.
    
    .EXAMPLE
        $progress = Start-ProgressActivity -Activity "Processing files" -Status "Starting..." -TotalItems 10
        # ... processing ...
        $progress.Stop(@{ Status = "All files processed successfully" })
        
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
        
    .EXAMPLE
        # Simple stop with default status
        $progress.Stop()
        
        # Stop with custom status
        $progress.Stop(@{ Status = "Operation completed" })
        
        # Stop with error
        $progress.Stop(@{ Status = "Something went wrong"; IsError = $true })
    #>
    [void] Stop([hashtable]$inputParams = @{}) {
        if ($this.IsCompleted) {
            return  # Already stopped
        }
        
        $this.IsCompleted = $true
        
        # Extract parameters from hashtable with defaults
        $newStatus = $inputParams.Status ?? 'Completed'
        $newIsError = $inputParams.IsError ?? $false
        
        # Build completion parameters
        $progressParams = @{
            Activity  = $this.Activity
            Id        = $this.Id
            Completed = $true
        }
        
        if ($this.ParentId -ge 0) {
            $progressParams.ParentId = $this.ParentId
        }
        
        # Show appropriate status
        if ($newIsError) {
            $progressParams.Status = "Error: $newStatus"
        }
        else {
            $progressParams.Status = $newStatus
            $progressParams.PercentComplete = 100
        }
        
        # Complete the progress bar
        Write-Progress @progressParams
    }
    
    # Private method to update the progress bar
    hidden [void] _UpdateProgressBar() {
        $progressParams = @{
            Activity = $this.Activity
            Status   = $this.Status
            Id       = $this.Id
        }
        
        if ($this.ParentId -ge 0) {
            $progressParams.ParentId = $this.ParentId
        }
        
        # Determine what to show for progress
        if ($this.PercentComplete -ge 0) {
            $progressParams.PercentComplete = $this.PercentComplete
        }
        elseif ($this.CurrentItem -ge $this.TotalItems) {
            $progressParams.PercentComplete = 100
        }
        elseif (($this.TotalItems -gt 0) -and ($this.CurrentItem -ge 0)) {
            $progressParams.PercentComplete = [int]($this.CurrentItem / $this.TotalItems * 100)
        }
        
        if ($this.SecondsRemaining -ge 0) {
            $progressParams.SecondsRemaining = $this.SecondsRemaining
        }

        # Update the progress bar
        Write-Progress @progressParams
    }
} 