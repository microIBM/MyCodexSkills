#requires -Version 7.0

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Pin stdout to UTF-8 so accented payload text (Spanish goal names/descriptions)
# survives when the caller (Node/MCP) decodes the pipe as UTF-8, regardless of the
# host console codepage (CP437/CP1252 on many Windows shells). ConvertFrom-Json
# -Depth below also requires PowerShell 7+.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-PowerBiBearerToken {
    param(
        [string] $AccessToken
    )

    if ($AccessToken) {
        return $AccessToken
    }

    if ($env:POWERBI_ACCESS_TOKEN) {
        return $env:POWERBI_ACCESS_TOKEN
    }

    $az = Get-Command az -ErrorAction SilentlyContinue
    if ($az) {
        $token = az account get-access-token --resource 'https://analysis.windows.net/powerbi/api' --query accessToken -o tsv
        if ($LASTEXITCODE -eq 0 -and $token) {
            return $token.Trim()
        }
    }

    throw 'No Power BI access token found. Set POWERBI_ACCESS_TOKEN or sign in with Azure CLI.'
}

function Read-JsonObject {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "JSON file not found: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
}

function ConvertTo-JsonBody {
    param(
        [Parameter(Mandatory = $true)]
        [object] $InputObject
    )

    return $InputObject | ConvertTo-Json -Depth 100
}

function Assert-ConfirmedWrite {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Action,

        [switch] $ConfirmWrite
    )

    if (-not $ConfirmWrite) {
        throw "Write action '$Action' requires -ConfirmWrite."
    }
}

function Assert-RequiredValue {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [AllowNull()]
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Name is required."
    }
}

function ConvertTo-PowerBiPathSegment {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Value,

        [string] $Name = 'Value'
    )

    Assert-RequiredValue -Name $Name -Value $Value
    return [System.Uri]::EscapeDataString($Value)
}

function Resolve-PowerBiRestUri {
    param(
        [Parameter(Mandatory = $true)]
        [string] $BaseUri,

        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $parsedBaseUri = [System.Uri] $BaseUri
    if (
        -not $parsedBaseUri.IsAbsoluteUri -or
        $parsedBaseUri.Scheme -ne 'https' -or
        $parsedBaseUri.Host -ne 'api.powerbi.com' -or
        $parsedBaseUri.UserInfo
    ) {
        throw 'Power BI REST calls must target https://api.powerbi.com without userinfo.'
    }

    return "$($BaseUri.TrimEnd('/'))/$($Path.TrimStart('/'))"
}

function New-PowerBiScorecardPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $GroupId,

        [string] $ScorecardId,

        [string] $Suffix
    )

    $encodedGroupId = ConvertTo-PowerBiPathSegment -Name 'GroupId' -Value $GroupId
    $path = "groups/$encodedGroupId/scorecards"
    if ($ScorecardId) {
        $encodedScorecardId = ConvertTo-PowerBiPathSegment -Name 'ScorecardId' -Value $ScorecardId
        $path = "$path($encodedScorecardId)"
    }
    if ($Suffix) {
        $path = "$path/$Suffix"
    }
    return $path
}

function Invoke-PowerBiRest {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PATCH', 'DELETE')]
        [string] $Method,

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [object] $Body,

        [string] $AccessToken,

        [string] $BaseUri = 'https://api.powerbi.com/v1.0/myorg'
    )

    $uri = Resolve-PowerBiRestUri -BaseUri $BaseUri -Path $Path
    $token = Get-PowerBiBearerToken -AccessToken $AccessToken
    $headers = @{
        Authorization = "Bearer $token"
    }

    $parameters = @{
        Method = $Method
        Uri = $uri
        Headers = $headers
    }

    if ($null -ne $Body) {
        $parameters.ContentType = 'application/json'
        $parameters.Body = ConvertTo-JsonBody -InputObject $Body
    }

    try {
        $response = Invoke-RestMethod @parameters
    }
    catch {
        # Map the common Power BI REST failures to an actionable message instead
        # of surfacing a raw .NET HttpResponseException. Token expiry (401) is the
        # routine case because az-CLI tokens expire in ~1 hour.
        $status = $null
        try { $status = [int]$_.Exception.Response.StatusCode } catch { }
        $hint = switch ($status) {
            401 { 'token missing/expired/invalid — re-run `az login` (az CLI tokens expire in ~1h) or refresh $env:POWERBI_ACCESS_TOKEN' }
            403 { 'insufficient Power BI permissions for this workspace/scorecard' }
            404 { 'workspace, scorecard, or goal not found — verify the GUID(s) in the request' }
            429 { 'rate-limited by the Power BI API — wait a moment and retry' }
            default { $_.Exception.Message }
        }
        $label = if ($status) { "HTTP $status" } else { 'request failed' }
        [Console]::Error.WriteLine("Power BI REST $Method $uri : $label — $hint")
        exit 1
    }

    if ($null -ne $response) {
        $response | ConvertTo-Json -Depth 100
    }
}
