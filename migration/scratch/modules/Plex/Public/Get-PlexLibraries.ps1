function Get-PlexLibraries {
    <#
    .SYNOPSIS
        Retrieves all libraries from a Plex Media Server.
    
    .DESCRIPTION
        Gets a list of all libraries (sections) from a Plex Media Server including
        movies, TV shows, music, photos, and other media types. This function provides
        information about each library including its ID, name, type, and content count.
    
    .PARAMETER Credential
        The Plex credential object containing server URL and authentication token.
    
    .PARAMETER LibraryType
        Filter libraries by type (Movie, Show, Music, Photo, HomeVideo, MusicVideo, Podcast, Audiobook).
        If not specified, returns all libraries.
    
    .PARAMETER TimeoutSec
        The timeout in seconds for the request. Defaults to 30.
    
    .EXAMPLE
        $cred = Get-PlexCredential
        Get-PlexLibraries -Credential $cred
        
        Gets all libraries using credentials.
    
    .EXAMPLE
        $cred = Get-PlexCredential
        Get-PlexLibraries -Credential $cred -LibraryType Movie
        
        Gets only movie libraries using credentials.
    
    .OUTPUTS
        [PSCustomObject[]] Array of objects containing library information.
    
    .NOTES
        This function requires a valid Plex token to access library information.
        Library types correspond to the Plex API library type IDs.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PlexCredential is a custom type containing PSCredential, not plain text')]
    param(
        [Parameter(Mandatory = $true)]
        [PlexCredential]$Credential,
        
        [Parameter()]
        [ValidateSet('Movie', 'Show', 'Music', 'Photo', 'HomeVideo', 'MusicVideo', 'Podcast', 'Audiobook')]
        [string]$LibraryType,
        
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    
    try {
        Write-Message "Retrieving libraries from: $($Credential.ServerUrl)" -Type Processing
        
        # Make the request using relative path
        $response = Invoke-PlexApiRequest -Uri $Script:PlexApiEndpoints.Libraries -Credential $Credential -TimeoutSec $TimeoutSec
        
        if ($response -and $response.MediaContainer -and $response.MediaContainer.Directory) {
            $libraries = $response.MediaContainer.Directory
            
            # Filter by library type if specified
            if ($LibraryType) {
                $typeId = $Script:PlexLibraryTypes[$LibraryType]
                $libraries = $libraries | Where-Object { $_.type -eq $typeId }
                Write-Message "Filtered to $LibraryType libraries" -Type Verbose
            }
            
            # Convert to custom objects
            $result = $libraries | ForEach-Object {
                [PSCustomObject]@{
                    Id = $_.key
                    Title = $_.title
                    Type = $_.type
                    TypeName = $_.typeTitle
                    Agent = $_.agent
                    Scanner = $_.scanner
                    Language = $_.language
                    UUID = $_.uuid
                    UpdatedAt = $_.updatedAt
                    CreatedAt = $_.createdAt
                    ScannedAt = $_.scannedAt
                    Content = $_.content
                    Directory = $_.directory
                    Count = $_.count
                    Art = $_.art
                    Thumb = $_.thumb
                    Banner = $_.banner
                    Theme = $_.theme
                    Primary = $_.primary
                    Prominent = $_.prominent
                    EnableAutoPhotoTags = $_.enableAutoPhotoTags
                    EnableBIFGeneration = $_.enableBIFGeneration
                    EnableCinemaTrailers = $_.enableCinemaTrailers
                    EnablePhotoTranscoding = $_.enablePhotoTranscoding
                    EnableSmART = $_.enableSmART
                    IncludeInGlobal = $_.includeInGlobal
                    Name = $_.name
                    Refreshing = $_.refreshing
                }
            }
            
            Write-Message "✅ Successfully retrieved $($result.Count) libraries" -Type Success
            
            return $result
        }
        else {
            Write-Message "❌ Failed to retrieve libraries - invalid response format" -Type Error
            return @()
        }
    }
    catch {
        Write-Message "❌ Failed to retrieve libraries: $($_.Exception.Message)" -Type Error
        throw
    }
} 