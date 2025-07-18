function Invoke-PlexApiRequest {
    <#
    .SYNOPSIS
        Makes HTTP requests to the Plex API with proper error handling and logging.
    .DESCRIPTION
        This private function handles all HTTP requests to the Plex API, providing
        consistent error handling, logging, and response processing across the module.
        It automatically handles authentication headers, timeout settings, and common
        error scenarios.
        The function automatically adds the X-Plex-Token header when a Plex credential is provided,
        and includes standard Plex API headers for proper client identification.
    .PARAMETER Uri
        The relative path to request from the Plex API (e.g., "/library/sections").
    .PARAMETER Method
        The HTTP method to use (GET, POST, PUT, DELETE). Defaults to GET.
    .PARAMETER Connection
        The Plex connection object containing the authentication token. Required for most API endpoints.
    .PARAMETER Headers
        Additional headers to include in the request.
    .PARAMETER Body
        The request body for POST/PUT requests.
    .PARAMETER PlexBodyFormat
        The format to return the response in. Defaults to Auto, causes the API to return the raw response as a string
    .EXAMPLE
        $connection = New-PlexConnection
        $response = Invoke-PlexApiRequest $connection -Uri "/library/sections"
    .EXAMPLE
        $connection = New-PlexConnection
        $response = Invoke-PlexApiRequest $connection -Uri "/library/sections/1/refresh" -Method POST
    .OUTPUTS
        [PSCustomObject] The parsed JSON response from the Plex API.
    .NOTES
        This function is designed to be used internally by other Plex module functions.
        It provides consistent error handling and logging for all API interactions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNull()]
        [object]$Connection,
        [Parameter(Mandatory, Position = 1)]
        [PlexEndpoint]$Endpoint,
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,
        [Parameter()]
        [hashtable]$Headers = @{},
        [Parameter()]
        [object]$Body,
        [Parameter()]
        [PlexBodyFormat]$PlexBodyFormat = [PlexBodyFormat]::Json
    )
    return $Connection.GetApiResponse($Endpoint, $Method, $Headers, $Body, $PlexBodyFormat)
}