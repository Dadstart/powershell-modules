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
    .PARAMETER TimeoutSec
        The timeout in seconds for the request. Defaults to 30.
    .EXAMPLE
        $connection = New-PlexConnection
        $response = Invoke-PlexApiRequest -Uri "/library/sections" -Connection $connection
    .EXAMPLE
        $connection = New-PlexConnection
        $response = Invoke-PlexApiRequest -Uri "/library/sections/1/refresh" -Method POST -Connection $connection
    .OUTPUTS
        [PSCustomObject] The parsed JSON response from the Plex API.
    .NOTES
        This function is designed to be used internally by other Plex module functions.
        It provides consistent error handling and logging for all API interactions.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PlexCredential is a custom type containing PSCredential, not plain text')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^/[^\s]*$')]
        [string]$Uri,
        [Parameter()]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE')]
        [string]$Method = 'GET',
        [Parameter()]
        [object]$Connection,
        [Parameter()]
        [hashtable]$Headers = @{},
        [Parameter()]
        [object]$Body,
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    try {
        # Build the full URI by combining server URL with relative path
        $fullUri = "$($Connection.ServerUrl)$Uri"
        Write-Message "Making $Method request to: $fullUri" -Type Verbose
        # Merge default headers with provided headers
        $requestHeaders = $Script:PlexDefaultHeaders.Clone()
        foreach ($key in $Headers.Keys) {
            $requestHeaders[$key] = $Headers[$key]
        }
        # Add authentication token if provided
        if ($Connection) {
            $requestHeaders['X-Plex-Token'] = $Connection.Token
            Write-Message "Using authentication token" -Type Debug
        }
        else {
            Write-Message "No authentication token provided - some endpoints may fail" -Type Warning
        }
        # Prepare request parameters
        $requestParams = @{
            Uri = $fullUri
            Method = $Method
            Headers = $requestHeaders
            TimeoutSec = $TimeoutSec
            ErrorAction = 'Stop'
        }
        # Add body if provided
        if ($Body) {
            $requestParams['Body'] = $Body
            Write-Message "Request body: $Body" -Type Debug
        }
        # Make the request
        $response = Invoke-RestMethod @requestParams
        Write-Message "Request completed successfully" -Type Verbose
        return $response
    }
    catch [System.Net.WebException] {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        Write-Message "HTTP request failed with status $statusCode : $statusDescription" -Type Error
        Write-Message "Request URI: $fullUri" -Type Debug
        Write-Message "Request Method: $Method" -Type Debug
        # Provide more specific error messages based on status code
        switch ($statusCode) {
            401 { 
                Write-Message "Authentication failed. Please check your Plex token." -Type Error
            }
            403 { 
                Write-Message "Access forbidden. Please check your permissions." -Type Error
            }
            404 { 
                Write-Message "Resource not found. Please check the URI: $Uri" -Type Error
            }
            500 { 
                Write-Message "Plex server error. Please try again later." -Type Error
            }
            default {
                Write-Message "Unexpected HTTP error: $statusCode" -Type Error
            }
        }
        throw
    }
    catch {
        Write-Message "Request failed with error: $($_.Exception.Message)" -Type Error
        Write-Message "Request URI: $fullUri" -Type Debug
        throw
    }
} 
