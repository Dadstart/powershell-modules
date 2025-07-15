[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$To,
    [Parameter(Mandatory, Position = 1)]
    [string]$Text,
    [switch]$Pretty
)

$body = @{
    'from' = '+15122548579'
    'to'   = $To
    'text' = $Text
}
    
$uri = 'https://api.telnyx.com/v2/messages'
$headers = @{
    'Authorization' = "Bearer $($ENV:TELNYX_API_KEY)"
    'Content-Type'  = 'application/json'
}
$response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)
    
if ($Pretty) {
    Write-Host "`n===== RESPONSE =====" -ForegroundColor Green
    Write-Host "StatusCode: $($response.StatusCode) ($($response.StatusDescription))"

    Write-Host "`n===== HEADERS =====" -ForegroundColor Cyan
    $response.Headers.GetEnumerator() | ForEach-Object {
        $value = $_.Value | ConvertTo-Json | ConvertFrom-Json
        Write-Host ('{0}: {1}' -f $_.Key, $value)
    }

    Write-Host "`n===== BODY =====" -ForegroundColor Green
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 3 | Write-Host
}
else {
    $response
}
    