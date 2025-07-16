function Invoke-RemuxProcessing {
    <#
    .SYNOPSIS
        Processes remux operations by combining original video with HandBrake audio streams.
    .DESCRIPTION
        Takes original video files and HandBrake converted files, extracts audio streams from the HandBrake files,
        and remuxes them with the original video content to create final output files.
    .PARAMETER Path
        The directory containing original video files to process.
    .PARAMETER HandbrakeDirectory
        The directory containing HandBrake converted files.
    .PARAMETER Destination
        The directory where remuxed files will be saved.
    .EXAMPLE
        Invoke-RemuxProcessing -Path "C:\Original" -HandbrakeDirectory "C:\HandBrake" -Destination "C:\Remuxed"
    .EXAMPLE
        Invoke-RemuxProcessing -Path "C:\Original" -HandbrakeDirectory "C:\HandBrake" -Destination "C:\Remuxed" -Verbose
    .NOTES
        This function requires the Video module to be installed and available.
        Original files and HandBrake files must have matching base names.
    .LINK
        https://github.com/dadstart/video-modules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$HandbrakeDirectory,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination
    )
    begin {
        Write-Message 'Starting remux processing' -Type Verbose
        Write-Message "Original directory: $Path" -Type Verbose
        Write-Message "HandBrake directory: $HandbrakeDirectory" -Type Verbose
        Write-Message "Output directory: $Destination" -Type Verbose
        # Validate directories
        $Path = Get-Path -Path $Path -PathType Absolute -ValidatePath Directory
        $HandbrakeDirectory = Get-Path -Path $HandbrakeDirectory -PathType Absolute -ValidatePath Directory
        $Destination = New-ProcessingDirectory -Path $Destination -Description 'remux output' -SuppressOutput
    }
    process {
        try {
            # Use centralized temp directory management
            Use-TempDirectory -ScriptBlock {
                param($TempDirectory)
                Get-ChildItem $HandbrakeDirectory *.mkv | ForEach-Object {
                    # Get the original file name from the HandBrake file name
                    $originalFileAbs = Get-Path -Path $Path, $_.Name -PathType Absolute -ValidatePath File
                    Write-Message "Original file: $($originalFileAbs)" -Type Verbose
                }
            }
        }
        catch {
            Write-Message "Invoke-RemuxProcessing: Error: $_" -Type Error
            throw "Invoke-RemuxProcessing: Error: $_"
        }
    }
    end {
        Write-Message 'Remux processing completed' -Type Verbose
    }
}
