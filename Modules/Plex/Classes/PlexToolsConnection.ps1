enum PlexBodyFormat {
    Raw     # Return the raw response as a string
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
    hidden [System.Net.Http.HttpClient]$Client
    [int]$TimeoutSeconds

    PlexToolsConnection(
        [pscredential]$credential,
        [string]$serverUrl,
        [string]$token) {

        if (-not $credential) {
            throw [ArgumentNullException]::new('credential')
        }
        if (-not $token) {
            throw [ArgumentNullException]::new('token')
        }
        $this.Credential = $credential
        $this.ServerUrl = $serverUrl.TrimEnd('/')
        $this.Token = $token

        # Initialize HTTP client
        $this.Client = [System.Net.Http.HttpClient]::new()

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

    hidden [string]GetBodyContentType([PlexBodyFormat]$plexBodyFormat) {
        switch ($plexBodyFormat) {
            [PlexBodyFormat]::Json {
                return 'application/json'
            }
            [PlexBodyFormat]::Xml {
                return 'application/xml, text/xml'
            }
            [PlexBodyFormat]::Raw {
                return 'text/plain'
            }
        }
        throw [ArgumentException]::new("Invalid body format: $plexBodyFormat")
    }

    hidden [PlexBodyFormat]GetBodyFormat([string]$contentType) {
        switch ($contentType) {
            'application/json' {
                return [PlexBodyFormat]::Json
            }
            'application/xml' {
                return [PlexBodyFormat]::Xml
            }
            'text/xml' {
                return [PlexBodyFormat]::Xml
            }
        }
        return [PlexBodyFormat]::Raw
    }

    [System.Threading.Tasks.Task[pscustomobject]] SendRequestAsync(
        [string]   $endpoint,
        [string]   $method,
        [hashtable]$queryParameters,
        [hashtable]$additionalHeaders,
        [object]   $body,
        [PlexBodyFormat]$requestFormat,
        [PlexBodyFormat]$responseFormat
    ) {
        # override $null parameters with defaults
        $method = $method ?? 'GET'
        $requestFormat = $requestFormat ?? [PlexBodyFormat]::Json
        $responseFormat = $responseFormat ?? [PlexBodyFormat]::Raw
        $queryParameters = $queryParameters ?? @{}
        $additionalHeaders = $additionalHeaders ?? @{}

        # Build the full URI with encoded query parameters
        $base = "$($this.ServerUrl)/$endpoint".TrimEnd('/')
        if ($queryParameters.Count) {
            $queryParamsArgs = $queryParameters.GetEnumerator() |
                ForEach-Object {
                    $k = [Uri]::EscapeDataString($_.Key)
                    $v = [Uri]::EscapeDataString($_.Value.ToString())
                    $queryParam = "$k"
                    if ($v) {
                        $queryParam += "=$v"
                    }
                    $queryParam
                } -Join '&'
            $url = "$base`?$queryParamsArgs"
        }
        else {
            $url = $base
        }

        Write-Host "=> $method $url" -ForegroundColor Cyan

        # Create and populate the request
        $request = [System.Net.Http.HttpRequestMessage]::new(
            [System.Net.Http.HttpMethod]::$method, $url
        )

        # Add headers, starting with defaults
        $defaultHeaders = $this.GetHeaders()
        foreach ($key in $defaultHeaders.Keys) {
            $request.Headers.Add($key, $defaultHeaders[$key])
        }
        $request.Headers.Accept.Add(
            [System.Net.Http.Headers.MediaTypeWithQualityHeaderValue]::new($this.GetBodyContentType($requestFormat))
        )
        if ($this.Token) {
            $request.Headers.Add('X-Plex-Token', $this.Token)
        }
        foreach ($key in $additionalHeaders.Keys) {
            $request.Headers.Add($key, $additionalHeaders[$key])
        }

        if ($method -eq 'POST' -and $body) {
            $encodedBody = switch ($requestFormat) {
                [PlexBodyFormat]::Json {
                    $body | ConvertTo-Json -Depth 10
                }
                [PlexBodyFormat]::Xml {
                    $body | ConvertTo-Xml -Depth 10
                }
                default {
                    $body
                }
            }

            $request.Content = [System.Net.Http.StringContent]::new(
                $encodedBody,
                [System.Text.Encoding]::UTF8,
                $this.GetBodyContentType($requestFormat)
            )
        }

        return $this.Client.SendAsync($request).ContinueWith({
                param($task)

                $convertDepth = 10
                try {
                    $response = $task.Result
                    $rawBody = $response.Content.ReadAsStringAsync().Result
                    $success = $response.IsSuccessStatusCode

                    Write-Host ($(
                            $success ?
                            "<= $($response.StatusCode) $url" :
                            "<! $($response.StatusCode) $url")
                    ) -ForegroundColor (if ($success) { 'Green' } else { 'Red' })

                    $decodedBody = switch ($responseFormat) {
                        [PlexBodyFormat]::Json {
                            $rawBody | ConvertFrom-Json -Depth $convertDepth -ErrorAction SilentlyContinue
                        }
                        [PlexBodyFormat]::Xml {
                            $rawBody | ConvertFrom-Xml -Depth $convertDepth -ErrorAction SilentlyContinue
                        }
                        default {
                            $rawBody
                        }
                    }

                    return [pscustomobject]@{
                        StatusCode = $response.StatusCode
                        Reason     = $response.ReasonPhrase
                        Headers    = $response.Headers
                        Content    = $decodedBody
                    }
                }
                catch {
                    Write-Host "<X Request failed: $_" -ForegroundColor Red
                    throw
                }
            })
    }

    hidden [System.Threading.Tasks.Task[pscustomobject]] SendRequest(
        [string]   $endpoint,
        [string]   $method,
        [hashtable]$queryParameters,
        [hashtable]$headers,
        [object]   $body,
        [PlexBodyFormat]$requestFormat,
        [PlexBodyFormat]$responseFormat
    ) {
        return $this.SendRequestAsync($endpoint, $method, $queryParameters, $headers, $body, $requestFormat, $responseFormat).Result
    }

    [System.Threading.Tasks.Task[pscustomobject[]]] InvokePaginatedRequestAsync(
        [string]   $endpoint,
        [hashtable]$queryParameters,
        [hashtable]$additionalHeaders,
        [int]      $pageSize,
        [PlexBodyFormat]$requestFormat,
        [PlexBodyFormat]$responseFormat
    ) {
        # initialize parameters to their defaults
        $queryParameters = $queryParameters ?? @{}
        $pageSize = $pageSize ?? 100

        $itemsList = [System.Collections.Generic.List[object]]::new()
        $offset = 0

        $task = [System.Threading.Tasks.Task]::Run({
                do {
                    $queryParameters['X-Plex-Container-Start'] = $offset
                    $queryParameters['X-Plex-Container-Size'] = $pageSize


                    $responseTask = $this.SendRequestAsync($endpoint, 'GET', $queryParameters, $additionalHeaders, $null, $requestFormat, $responseFormat)
                    $response = $responseTask.Result

                    if (-not $response.Content -or -not $response.Content.MediaContainer) {
                        break
                    }

                    if ($response.Content.MediaContainer.Directory) {
                        $chunk = $response.Content.MediaContainer.Directory
                    }
                    elseif ($response.Content.MediaContainer.Metadata) {
                        $chunk = $response.Content.MediaContainer.Metadata
                    }
                    else {
                        break
                    }

                    $itemsList.AddRange($chunk)
                    $offset += $pageSize
                    $count = $chunk.Count
                } while ($count -eq $pageSize)

                return , $itemsList.ToArray()
            })

        return $task
    }

    [psobject[]] InvokePaginatedRequest(
        [string]   $endpoint,
        [hashtable]$queryParameters,
        [hashtable]$headers,
        [int]      $pageSize
    ) {
        return $this.InvokePaginatedRequestAsync($endpoint, $queryParameters, $headers, $pageSize).Result
    }

    [object]GetApiResponse(
        [PlexEndpoint]$Endpoint,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,
        [hashtable]$AdditionalHeaders,
        [object]$Body,
        [PlexBodyFormat]$PlexBodyFormat
    ) {
        $url = $this.GetApiEndpointUrl($Endpoint)
        try {
            # Build the full URI by combining server URL with relative path
            Write-Message "Making $Method request to $Endpoint ($url)" -Type Verbose

            # Merge default headers with provided headers
            $requestHeaders = $this.GetHeaders()
            if ($AdditionalHeaders) {
                foreach ($key in $AdditionalHeaders.Keys) {
                    $requestHeaders[$key] = $AdditionalHeaders[$key]
                }
            }

            # Add response format
            $acceptType = switch ($PlexBodyFormat) {
                [PlexBodyFormat]::Json {
                    'application/json'
                }
                [PlexBodyFormat]::Xml {
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
            switch ($PlexBodyFormat) {
                [PlexBodyFormat]::Json {
                    $response = $response | ConvertFrom-Json
                }
                [PlexBodyFormat]::Xml {
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
