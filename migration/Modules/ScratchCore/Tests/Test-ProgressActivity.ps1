function Test-ProgressActivity {
    <#
    .SYNOPSIS
        Tests the ProgressActivity class functionality.
    
    .DESCRIPTION
        Demonstrates and tests all features of the ProgressActivity class including:
        - Basic progress operations
        - Error handling
        - Nested progress bars
        - Different progress types (determinate, indeterminate, percentage-based)
        - Method parameter variations
    
    .EXAMPLE
        Test-ProgressActivity
        
        Runs all progress activity tests with visual progress bars.
    #>
    [CmdletBinding()]
    param()
    
    Write-Message 'Testing ProgressActivity class...' -Type Info
    
    # Test 1: Basic determinate progress
    Write-Message "`nTest 1: Basic determinate progress" -Type Info
    $progress = Start-ProgressActivity -Activity 'Processing files' -Status 'Starting file processing...' -TotalItems 5
    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Milliseconds 300
        $updateParams = 
        Write-Host "➡ Args Type: $($updateParams.GetType().FullName)"
        $progress.Update(@{ CurrentItem = $i; Status = "Processing file $i.txt" })
    }
    $progress.Stop(@{ Status = 'All files processed successfully' })
    
    # Test 2: Indeterminate progress
    Write-Message "`nTest 2: Indeterminate progress" -Type Info
    $progress = Start-ProgressActivity -Activity 'Waiting for something' -Status 'Waiting...'
    for ($i = 1; $i -le 5; $i++) {
        Start-Sleep -Milliseconds 400
        $progress.Update(@{ Status = "Still waiting... ($i/5)" })
    }
    $progress.Stop(@{ Status = 'Finished waiting' })
    
    # Test 3: Percentage-based progress
    Write-Message "`nTest 3: Percentage-based progress" -Type Info
    $progress = Start-ProgressActivity -Activity 'Downloading' -Status 'Starting download...'
    for ($i = 0; $i -le 100; $i += 10) {
        Start-Sleep -Milliseconds 200
        $progress.Update(@{ Status = "$i% complete"; PercentComplete = $i })
    }
    $progress.Stop(@{ Status = 'Download completed' })
    
    # Test 4: Error handling
    Write-Message "`nTest 4: Error handling" -Type Info
    $progress = Start-ProgressActivity -Activity 'Risky operation' -Status 'Starting risky operation...' -TotalItems 3
    try {
        for ($i = 1; $i -le 3; $i++) {
            Start-Sleep -Milliseconds 250
            $progress.Update(@{ CurrentItem = $i; Status = "Processing step $i" })
            
            # Simulate an error on step 2
            if ($i -eq 2) {
                throw "Something went wrong on step $i"
            }
        }
        $progress.Stop(@{ Status = 'Operation completed successfully' })
    }
    catch {
        $progress.Stop(@{ Status = $_.Exception.Message; IsError = $true })
        Write-Message "Caught expected error: $($_.Exception.Message)" -Type Warning
    }
    
    # Test 5: Nested progress bars
    Write-Message "`nTest 5: Nested progress bars" -Type Info
    $mainProgress = Start-ProgressActivity -Activity 'Main operation' -Status 'Starting main operation...' -TotalItems 3 -Id 1
    for ($i = 1; $i -le 3; $i++) {
        $mainProgress.Update(@{ CurrentItem = $i; Status = "Main step $i" })
        
        # Nested progress for each main step
        $subProgress = Start-ProgressActivity -Activity "Sub-operation $i" -Status 'Starting sub-operation...' -TotalItems 4 -Id 2 -ParentId 1
        for ($j = 1; $j -le 4; $j++) {
            Start-Sleep -Milliseconds 150
            $subProgress.Update(@{ CurrentItem = $j; Status = "Sub-step $j" })
        }
        $subProgress.Stop(@{ Status = "Sub-operation $i completed" })
    }
    $mainProgress.Stop(@{ Status = 'Main operation completed' })
    
    # Test 6: Method parameter variations
    Write-Message "`nTest 6: Method parameter variations" -Type Info
    $progress = Start-ProgressActivity -Activity 'Parameter test' -Status 'Starting parameter test...' -TotalItems 4
    
    # Update only current item
    $progress.Update(@{ CurrentItem = 1 })
    Start-Sleep -Milliseconds 200
    
    # Update only status
    $progress.Update(@{ Status = 'Updated status only' })
    Start-Sleep -Milliseconds 200
    
    # Update only percentage
    $progress.Update(@{ PercentComplete = 50 })
    Start-Sleep -Milliseconds 200
    
    # Update only time remaining
    $progress.Update(@{ SecondsRemaining = 30 })
    Start-Sleep -Milliseconds 200
    
    # Update multiple parameters
    $progress.Update(@{ CurrentItem = 4; Status = 'Final update'; PercentComplete = 100; SecondsRemaining = 0 })
    Start-Sleep -Milliseconds 200
    
    $progress.Stop(@{ Status = 'Parameter test completed' })
    
    # Test 7: Multiple progress bars (different IDs)
    Write-Message "`nTest 7: Multiple progress bars" -Type Info
    $progress1 = Start-ProgressActivity -Activity 'Operation A' -Status 'Starting A...' -TotalItems 3 -Id 10
    $progress2 = Start-ProgressActivity -Activity 'Operation B' -Status 'Starting B...' -TotalItems 3 -Id 11
    
    for ($i = 1; $i -le 3; $i++) {
        $progress1.Update(@{ CurrentItem = $i; Status = "A step $i" })
        $progress2.Update(@{ CurrentItem = $i; Status = "B step $i" })
        Start-Sleep -Milliseconds 300
    }
    
    $progress1.Stop(@{ Status = 'Operation A completed' })
    $progress2.Stop(@{ Status = 'Operation B completed' })
    
    # Test 8: Stop without parameters
    Write-Message "`nTest 8: Stop without parameters" -Type Info
    $progress = Start-ProgressActivity -Activity 'Simple operation' -Status 'Starting...'
    Start-Sleep -Milliseconds 500
    $progress.Stop(@{ Status = 'Completed' })  # Uses default "Completed" status
    
    # Test 9: Double stop (should be safe)
    Write-Message "`nTest 9: Double stop (should be safe)" -Type Info
    $progress = Start-ProgressActivity -Activity 'Double stop test' -Status 'Starting...'
    Start-Sleep -Milliseconds 300
    $progress.Stop(@{ Status = 'First stop' })
    $progress.Stop(@{ Status = 'Second stop' })  # Should be ignored
    
    Write-Message "`nAll ProgressActivity tests completed!" -Type Success
} 