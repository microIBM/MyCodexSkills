# install-tabular-editor.ps1
# Detects Tabular Editor 2 (free, MIT) at the expected install path.
# With -Install, downloads the latest stable release ZIP from GitHub and
# extracts it to %LOCALAPPDATA%\TabularEditor\.
#
# Outputs the absolute path to TabularEditor.exe on stdout.
# Exit code: 0 = installed/found; non-zero = missing or infrastructure failure.
#
# Used by /bi-performance and /bi-modeling for Best Practice Analyzer
# and VertiPaq Analyzer integration.

#requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Install
)

$ErrorActionPreference = 'Stop'

function Get-LocalAppDataPath {
    $localAppData = $env:LOCALAPPDATA
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    }
    if ([string]::IsNullOrWhiteSpace($localAppData)) {
        throw 'LOCALAPPDATA is not set and LocalApplicationData could not be resolved.'
    }
    return $localAppData
}

function Assert-ValidAuthenticodeSignature {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Get-AuthenticodeSignature is a Windows-only cmdlet. If it is unavailable we
    # cannot verify; warn and proceed rather than blocking an otherwise-working
    # Tabular Editor install.
    if (-not (Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue)) {
        Write-Warning "Cannot check the Authenticode signature on this platform; skipping verification for ${FilePath}."
        return
    }

    $signature = Get-AuthenticodeSignature -FilePath $FilePath

    # Explicit tampering / trust failures are fatal — never run a binary that
    # fails these.
    $fatalStatuses = @('HashMismatch', 'NotTrusted', 'NotSigned')
    if ($fatalStatuses -contains $signature.Status) {
        throw "Authenticode signature validation failed for ${FilePath}: $($signature.Status)"
    }

    # 'Valid' is the happy path. Anything else (most often 'UnknownError' when the
    # certificate revocation servers are unreachable on offline / locked-down
    # corporate machines) is NOT evidence of tampering, so warn and continue
    # instead of aborting the Best Practice Analyzer run on a setup that worked
    # before.
    if ($signature.Status -ne 'Valid') {
        Write-Warning "Could not fully verify the Authenticode signature for ${FilePath} (status: $($signature.Status)). This is common on offline or locked-down machines; proceeding with the existing install."
    }
}

function Invoke-TabularEditorInstall {
    param(
        [switch]$Force,
        [switch]$Install
    )

    $installDir = Join-Path (Get-LocalAppDataPath) 'TabularEditor'
    $exePath = Join-Path $installDir 'TabularEditor.exe'

    if ((Test-Path $exePath) -and -not $Force) {
        Assert-ValidAuthenticodeSignature -FilePath $exePath
        Write-Output $exePath
        return
    }

    if (-not $Install) {
        throw "Tabular Editor 2 was not found at $exePath. Ask the user for permission, then rerun this script with -Install."
    }

    Write-Host "Tabular Editor 2 was not found at $installDir." -ForegroundColor Yellow
    Write-Host "Downloading the latest stable release from GitHub..." -ForegroundColor Yellow

    # GitHub API: latest release for the official Tabular Editor 2 repo
    $apiUrl = 'https://api.github.com/repos/TabularEditor/TabularEditor/releases/latest'

    try {
        $headers = @{ 'User-Agent' = 'bi-superpowers-installer' }
        if ($env:GITHUB_TOKEN) {
            $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
        }
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing
    }
    catch {
        throw "Could not query the GitHub releases API: $($_.Exception.Message). If this is a rate-limit error, set GITHUB_TOKEN and rerun."
    }

    # Pick the standard Windows ZIP. Prefer the non-portable ZIP when both assets
    # exist because it matches the expected TabularEditor.exe layout.
    $asset = $release.assets |
        Where-Object { $_.name -match '\.zip$' -and $_.name -notmatch 'portable' } |
        Select-Object -First 1

    if (-not $asset) {
        throw "No Windows ZIP asset was found in release $($release.tag_name)."
    }

    $assetUri = [System.Uri]$asset.browser_download_url
    if (-not $assetUri.IsAbsoluteUri -or $assetUri.Scheme -ne 'https' -or $assetUri.Host -notmatch '(^|\.)github\.com$') {
        throw "Unexpected Tabular Editor asset host: $($assetUri.Host)"
    }

    $tempZip = Join-Path $env:TEMP "TabularEditor_$([guid]::NewGuid().ToString('N')).zip"

    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempZip -UseBasicParsing -Headers $headers
    }
    catch {
        throw "Download failed for $($asset.browser_download_url): $($_.Exception.Message)"
    }

    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    try {
        Expand-Archive -Path $tempZip -DestinationPath $installDir -Force
    }
    finally {
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    }

    if (-not (Test-Path $exePath)) {
        throw "Installation completed, but $exePath was not found. Check the contents of $installDir."
    }

    Assert-ValidAuthenticodeSignature -FilePath $exePath

    Write-Host "Tabular Editor 2 installed: $exePath (version $($release.tag_name))" -ForegroundColor Green
    Write-Output $exePath
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-TabularEditorInstall -Force:$Force -Install:$Install
        exit 0
    }
    catch {
        [Console]::Error.WriteLine($_.Exception.Message)
        if (-not $Install -and $_.Exception.Message -match 'was not found') {
            exit 2
        }
        exit 1
    }
}
