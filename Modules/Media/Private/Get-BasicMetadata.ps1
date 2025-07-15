function Get-BasicMetadata {
    <#
    .SYNOPSIS
        Private function to extract basic metadata from media files.
    
    .DESCRIPTION
        Extracts basic file information and metadata.
        This is a private function called by the public Get-MediaMetadata function.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [MediaFile]$MediaFile,
        
        [Parameter()]
        [switch]$IncludeEmpty
    )
    
    try {
        Write-Message -Message "Extracting basic metadata from $($MediaFile.Name)" -Level Verbose
        
        # Get file information
        $FileInfo = Get-Item $MediaFile.Path
        
        $BasicMetadata = [PSCustomObject]@{
            FileName = $MediaFile.Name
            FileExtension = $MediaFile.Extension
            FileSize = $MediaFile.Size
            FileSizeFormatted = $MediaFile.GetFormattedSize()
            Created = $MediaFile.Created
            Modified = $MediaFile.Modified
            MediaType = $MediaFile.MediaType
            IsValid = $MediaFile.IsValid()
        }
        
        # Filter out empty values if not requested
        if (-not $IncludeEmpty) {
            $Properties = $BasicMetadata.PSObject.Properties | Where-Object { $_.Value -ne $null -and $_.Value -ne '' }
            $BasicMetadata = [PSCustomObject]@{}
            foreach ($Property in $Properties) {
                $BasicMetadata | Add-Member -MemberType NoteProperty -Name $Property.Name -Value $Property.Value
            }
        }
        
        return $BasicMetadata
    }
    catch {
        Write-Message -Message "Error extracting basic metadata: $_" -Level Error
        return $null
    }
} 