enum ResponseFormat {
    Auto    # Let the API decide based on Accept header
    Json    # Force JSON response
    Xml     # Force XML response
}

enum PlexEndpoint {
    Root
    ServerInfo
    Libraries
    LibraryItems
    MediaInfo
    LibraryScan
}

class PlexToolsConnection {
    <#
    .SYNOPSIS
        Represents Plex authentication credentials and server information.
    .DESCRIPTION
        The PlexToolsConnection class encapsulates all the information needed to authenticate
        with a Plex Media Server, including the server URL, username/password credentials,
        and authentication token.
    .PROPERTY Credential
        The PowerShell credential object containing username and password.
    .PROPERTY ServerUrl
        The URL of the Plex Media Server (e.g., "http://localhost:32400").
    .PROPERTY Token
        The Plex authentication token.
    .PROPERTY TimeoutSeconds
        The timeout value in seconds for API requests to the Plex server.
    .EXAMPLE
        $cred = [PlexToolsConnection]::new($psCredential, "http://localhost:32400", "token")
    .EXAMPLE
        $cred = Get-PlexToolsConnection
        $cred.ServerUrl
        $cred.Token
    #>
    hidden [pscredential]$Credential
    hidden [string]$ServerUrl
    hidden [string]$Token
    hidden [hashtable]$Headers
    [int]$TimeoutSeconds

    PlexToolsConnection([pscredential]$credential, [string]$serverUrl, [string]$token) {
        if (-not $credential) {
            throw [ArgumentNullException]::new('credential')
        }
        if (-not $token) {
            throw [ArgumentNullException]::new('token')
        }
        $this.Credential = $credential
        $this.ServerUrl = $serverUrl
        $this.Token = $token

        # Defaults
        $this.SetDefaultConfig()
    }

    [string]RefreshToken() {
        $this.Token = Get-PlexServerToken -Credential $this.Credential
        return $this.Token
    }

    [string]ToString() {
        return "PlexToolsConnection(ServerUrl='$($this.ServerUrl)', Username='$($this.Credential.UserName)'"
    }

    [hashtable]GetHeaders() {
        # Always return a clone so it can be modified without affecting the original
        return $this.Headers.Clone()
    }

    [object]GetApiResponse(
        [PlexEndpoint]$Endpoint,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [hashtable]$Headers,
        [object]$Body,
        [ResponseFormat]$ResponseFormat
    ) {
        $url = $this.GetApiEndpointUrl($Endpoint)
        try {
            # Build the full URI by combining server URL with relative path
            Write-Message "Making $Method request to $Endpoint ($url)" -Type Verbose

            # Merge default headers with provided headers
            $requestHeaders = $this.GetHeaders()
            if ($Headers) {
                foreach ($key in $Headers.Keys) {
                    $requestHeaders[$key] = $Headers[$key]
                }
            }

            # Add response format
            $acceptType = switch ($ResponseFormat) {
                [ResponseFormat]::Json {
                    'application/json'
                }
                [ResponseFormat]::Xml {
                    'application/xml, text/xml'
                }
                default: {
                    'application/json, application/xml, text/xml, */*'
                }
            }
            $requestHeaders['Accept'] = $acceptType

            # Add authentication token
            $requestHeaders['X-Plex-Token'] = $this.Token

            # Prepare request parameters
            $requestParams = @{
                Uri         = $url
                Method      = $Method
                Headers     = $requestHeaders
                TimeoutSec  = $this.TimeoutSeconds
                ErrorAction = 'Stop'
            }
            # Add body if provided
            if ($Body) {
                $requestParams['Body'] = $Body
                Write-Message "Request body: $Body" -Type Debug
            }
            # Make the request
            $response = Invoke-RestMethod @requestParams
            Write-Message 'Request completed successfully' -Type Verbose
            switch ($ResponseFormat) {
                [ResponseFormat]::Json {
                    $response = $response | ConvertFrom-Json
                }
                [ResponseFormat]::Xml {
                    $response = $response | ConvertFrom-Xml
                }
                default {
                    $response = ''
                }
            }

            return $response
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Message "HTTP request failed with status $statusCode : $statusDescription" -Type Error
            Write-Message "Request URI: $url" -Type Debug
            Write-Message "Request Method: $Method" -Type Debug
            # Provide more specific error messages based on status code
            switch ($statusCode) {
                401 {
                    Write-Message 'Authentication failed. Please check your Plex token.' -Type Error
                }
                403 {
                    Write-Message 'Access forbidden. Please check your permissions.' -Type Error
                }
                404 {
                    Write-Message "Resource not found. Please check the URI: $url" -Type Error
                }
                500 {
                    Write-Message 'Plex server error. Please try again later.' -Type Error
                }
                default {
                    Write-Message "Unexpected HTTP error: $statusCode" -Type Error
                }
            }
            throw $_
        }
        catch {
            Write-Message "Request failed with error: $($_.Exception.Message)" -Type Error
            Write-Message "Request URI: $url" -Type Debug
            throw $_
        }
    }

    hidden [string]GetApiEndpointUrl([PlexEndpoint]$Endpoint) {
        $endpointUrl =
        switch ($Endpoint) {
            'Root' {
                '/'
            }
            'ServerInfo' {
                '/library'
            }
            'Libraries' {
                '/library/sections'
            }
            'LibraryItems' {
                '/library/sections/{0}/all'
            }
            'MediaInfo' {
                '/library/metadata/{0}'
            }
            'LibraryScan' {
                '/library/sections/{0}/refresh'
            }
            default {
                throw [ArgumentException]::new("Invalid endpoint: $Endpoint")
            }
        }

        return "$($this.ServerUrl)$($endpointUrl)"
    }

    # Set the default configuration
    hidden [void]SetDefaultConfig() {
        $this.Headers = @{
            'X-Plex-Platform'          = 'Windows'
            'X-Plex-Platform-Version'  = '10'
            'X-Plex-Provides'          = 'controller'
            'X-Plex-Client-Identifier' = 'Dadstart PlexTools'
            'X-Plex-Product'           = 'Dadstart PlexTools'
            'X-Plex-Version'           = '0.0.1'
        }

        # Return default configuration if none exists
        $this.TimeoutSeconds = 30
    }
}
