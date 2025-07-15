# Plex Module Constants

# Default Plex server settings
$Script:PlexDefaultServer = 'localhost'
$Script:PlexDefaultPort = 32400
$Script:PlexDefaultProtocol = 'http'
$Script:PlexDefaultTimeout = 30

# Plex API endpoints
$Script:PlexApiEndpoints = @{
    ServerInfo = '/'
    Libraries = '/library/sections'
    LibraryItems = '/library/sections/{0}/all'
    MediaInfo = '/library/metadata/{0}'
    LibraryScan = '/library/sections/{0}/refresh'
    Search = '/search'
}

# Plex library types
$Script:PlexLibraryTypes = @{
    Movie = 1
    Show = 2
    Music = 8
    Photo = 3
    HomeVideo = 4
    MusicVideo = 6
    Podcast = 5
    Audiobook = 9
}

# Plex media types
$Script:PlexMediaTypes = @{
    Movie = 'movie'
    Episode = 'episode'
    Season = 'season'
    Show = 'show'
    Track = 'track'
    Album = 'album'
    Artist = 'artist'
    Photo = 'photo'
    Clip = 'clip'
}

# HTTP status codes for Plex API
$Script:PlexHttpStatusCodes = @{
    Success = 200
    Created = 201
    NoContent = 204
    BadRequest = 400
    Unauthorized = 401
    Forbidden = 403
    NotFound = 404
    ServerError = 500
}

# Default headers for Plex API requests
$Script:PlexDefaultHeaders = @{
    'Accept' = 'application/json'
    'X-Plex-Platform' = 'Windows'
    'X-Plex-Platform-Version' = '10'
    'X-Plex-Provides' = 'controller'
    'X-Plex-Client-Identifier' = 'PowerShell-Plex-Module'
    'X-Plex-Product' = 'PowerShell Plex Module'
    'X-Plex-Version' = '0.0.1'
} 