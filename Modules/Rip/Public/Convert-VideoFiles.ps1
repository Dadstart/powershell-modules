function Convert-VideoFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Files,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Format,
        [Parameter()]
        [string]$PresetFile,
        [Parameter()]
        [string[]]$HandbrakeOptions,
        [Parameter()]
        [switch]$Force
    )
    begin {
        $allFiles = @()
        Write-Message 'Initializing video conversion with pipeline support' -Type Verbose
        Write-Message "Destination: $Destination" -Type Verbose
        Write-Message "Format: $Format" -Type Verbose
        # Pass through verbose/debug preferences to called functions
        $PSDefaultParameterValues['Invoke-Process:Verbose'] = $VerbosePreference
        $PSDefaultParameterValues['Invoke-Process:Debug'] = $DebugPreference
    }
    process {
        if ($Files) {            
            $allFiles += $Files
        }
    }
    end {
        try {
            Write-Message "Convert-VideoFiles: Files: $($allFiles.Count) files to process" -Type Verbose
            # Validate preset file
            if ($PresetFile) {
                $PresetFile = Get-Path -Path $PresetFile -PathType Absolute -ValidatePath File
            }
            # Create output directory if it doesn't exist
            $Destination = New-ProcessingDirectory -Path $Destination -Description 'conversion output' -SuppressOutput
            Write-Message 'Convert-VideoFiles: Starting processing of files' -Type Verbose
            foreach ($file in $allFiles) {
                $inputFileAbs = Get-Path -Path $file -PathType Absolute -ValidatePath File
                Write-Message "Convert-VideoFiles: InputFileAbs: $inputFileAbs" -Type Debug
                $inputFileName = Get-Path -Path $inputFileAbs -PathType Leaf
                Write-Message "Convert-VideoFiles: InputFileName: $inputFileName" -Type Debug
                $outputFileAbs = Get-Path -Path $Destination, ([System.IO.Path]::ChangeExtension($inputFileName, ".$Format")) -PathType Absolute
                Write-Message "Convert-VideoFiles: OutputFileAbs: $outputFileAbs" -Type Debug
                $filePrefix = Get-Path -Path $inputFileName -PathType LeafBase
                Write-Message "Convert-VideoFiles: FilePrefix: $filePrefix" -Type Debug
                if (Test-Path -Path $outputFileAbs) {
                    if ($Force) {
                        Write-Message "Convert-VideoFiles: $filePrefix`: Output file already exists, but -Force is true, so overwriting" -Type Verbose
                        Remove-Item -Path $outputFileAbs -Force
                    }
                    else {
                        Write-Message "Convert-VideoFiles: $filePrefix`: Output file already exists. Use -Force to overwrite. (Destination path: $(Get-Path $outputFileAbs -PathType Parent))" -Type Warning
                        continue
                    }
                }
                $startTime = Get-Date
                Write-Message "Convert-VideoFiles: $filePrefix`: Conversion started at $startTime" -Type Verbose
                $extraArgs = @(
                    '--input', "`"$inputFileAbs`"",
                    '--output', "`"$outputFileAbs`""
                )
                if ($PresetFile) {
                    $extraArgs += "--preset-import-file `"$PresetFile`""
                }
                $fullArgs = @($HandbrakeOptions + $extraArgs)
                $handbrakeExe = $Script:HandBrakeCLIPath
                Write-Message "Convert-VideoFiles: $filePrefix`: HandBrake command: $handbrakeExe $($fullArgs -join ' ')" -Type Verbose
                # Use Invoke-Process to call HandBrakeCLI
                Write-Message '** Using Invoke-Process to call HandBrakeCLI with argument array' -Type Debug
                $processResult = Invoke-Process -Name $handbrakeExe -Arguments $fullArgs
                Write-Message "Convert-VideoFiles: Result:`n$processResult)" -Type Verbose
                if ($processResult.ExitCode) {
                    $errorMessage = "Convert-VideoFiles: HandBrake failed for $filePrefix with exit code: $($processResult.Error -join "`n")"
                    Write-Message $errorMessage -Type Error
                    throw $errorMessage
                }
                else {
                    Write-Message "Convert-VideoFiles: HandBrake conversion for $filePrefix completed successfully" -Type Verbose
                }
                <#
                    Call HandBrakeCLI directly
                    Write-Message "** Using & to call HandBrakeCLI with argument array" -Type Debug
                    $processResult = & $handbrakeExe @fullArgs
                    if ($LASTEXITCODE -ne 0) {
                        $errorMessage = "Convert-VideoFiles: HandBrake failed for $filePrefix with exit code: $LASTEXITCODE"
                        Write-Message $errorMessage -Type Error
                        throw $errorMessage
                    }
                    Write-Message "Convert-VideoFiles: HandBrake conversion for $filePrefix completed successfully" -Type Verbose
                    #>
                <#
                    # Use Start-Process to call HandBrakeCLI with argument array
                    Write-Message "** Using Start-Process to call HandBrakeCLI with argument array" -Type Debug
                    $process = Start-Process -FilePath $handbrakeExe -ArgumentList $fullArgs -Wait -NoNewWindow -PassThru
                    if ($process.ExitCode -ne 0) {
                        $errorMessage = "Convert-VideoFiles: HandBrake failed for $filePrefix with exit code: $($process.ExitCode)"
                        Write-Message $errorMessage -Type Error
                        throw $errorMessage
                    }
                    Write-Message "Convert-VideoFiles: HandBrake conversion for $filePrefix completed successfully" -Type Verbose
                    #>
                $endTime = Get-Date
                $elapsed = $endTime - $startTime
                Write-Message "Convert-VideoFiles: $filePrefix`: Conversion completed in $($elapsed.TotalMinutes.ToString('0.00')) minutes" -Type Verbose
                Get-Path -Path $outputFileAbs -PathType Absolute -ValidatePath File | Out-Null
                Write-Message "Convert-VideoFiles: $filePrefix`: Processing completed" -Type Verbose
            }
            return $allFiles
        }
        catch {
            Write-Message 'Convert-VideoFiles: Error:' -Type Debug
            Write-Message "Convert-VideoFiles:    Message: $($_.Exception.Message)" -Type Debug
            Write-Message "Convert-VideoFiles:    StackTrace: $($_.Exception.StackTrace)" -Type Debug
            Write-Message "Convert-VideoFiles:    TargetSite: $($_.Exception.TargetSite)" -Type Debug
            Write-Message "Convert-VideoFiles:    Data: $($_.Exception.Data)" -Type Debug
            Write-Message "Convert-VideoFiles:    HelpLink: $($_.Exception.HelpLink)" -Type Debug
            Write-Message "Convert-VideoFiles:    Source: $($_.Exception.Source)" -Type Debug
            Write-Message "Convert-VideoFiles:    HResult: $($_.Exception.HResult)" -Type Debug
            Write-Message "Convert-VideoFiles:    Data: $($_.Exception.Data)" -Type Debug
            Write-Message "Convert-VideoFiles: function failed with error: $($_.Exception.Message)" -Type Debug
            Write-Message "Convert-VideoFiles: Video conversion failed: $($_.Exception.Message)" -Type Error
            throw "Convert-VideoFiles: Video conversion failed: $($_.Exception.Message)"
        }
    }
} 
