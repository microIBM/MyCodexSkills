# run-bpa.ps1
# Runs the Microsoft Best Practice Rules (BPA) against the open
# Power BI Desktop semantic model using Tabular Editor 2 CLI.
#
# Auto-detects the AS port from the local PBI Desktop workspace and
# downloads the latest BPA rules JSON from microsoft/Analysis-Services.
#
# Usage:
#   pwsh run-bpa.ps1                       # default rules, autodetect port
#   pwsh run-bpa.ps1 -RulesUrl <url>       # override rules source
#   pwsh run-bpa.ps1 -Port 51234           # override port autodetect
#   pwsh run-bpa.ps1 -InstallTabularEditor # install TE2 after user consent
#
# Output: BPA findings to stdout. Exit 0 on success (regardless of finding count),
#         non-zero on infrastructure failure.

#requires -Version 7.0

[CmdletBinding()]
param(
    [string]$RulesUrl = 'https://raw.githubusercontent.com/microsoft/Analysis-Services/master/BestPracticeRules/BPARules.json',
    [switch]$AllowCustomRulesUrl,
    [int]$Port = 0,
    [string]$Database = '',
    [switch]$InstallTabularEditor
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Assert-SafeRulesUri {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [switch]$AllowCustomRulesUrl
    )

    $parsed = [System.Uri]$Uri
    if (-not $parsed.IsAbsoluteUri -or $parsed.Scheme -ne 'https') {
        throw 'RulesUrl must use HTTPS.'
    }

    if (-not $AllowCustomRulesUrl) {
        $expectedHost = 'raw.githubusercontent.com'
        $expectedPrefix = '/microsoft/Analysis-Services/'
        if ($parsed.Host -ne $expectedHost -or -not $parsed.AbsolutePath.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'RulesUrl must point to Microsoft Analysis-Services on raw.githubusercontent.com unless -AllowCustomRulesUrl is provided.'
        }
    }
}

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

function Get-BpaRulesCachePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RulesUrl,

        [Parameter(Mandatory = $true)]
        [string]$CacheRoot
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($RulesUrl.Trim())
        $hashBytes = $sha256.ComputeHash($bytes)
        $hash = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLowerInvariant()
        return Join-Path $CacheRoot "BPARules-$($hash.Substring(0, 16)).json"
    }
    finally {
        $sha256.Dispose()
    }
}

# Step 2 — Detect the live Power BI Desktop AS port (if not provided)
function Read-PowerBIPortFile {
    param([string]$Path)

    foreach ($encoding in @('Unicode', 'Default')) {
        $text = Get-Content $Path -Raw -Encoding $encoding -ErrorAction SilentlyContinue
        $digits = ($text -replace '[^\d]', '')
        $port = 0
        # TryParse + range guard: a corrupt/oversized port file must skip this
        # workspace gracefully, not overflow [int] and abort autodetection.
        if ($digits -and [int]::TryParse($digits, [ref]$port) -and $port -ge 1 -and $port -le 65535) {
            return $port
        }
    }

    return $null
}

function Test-LocalPort {
    param([int]$CandidatePort)

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect('127.0.0.1', $CandidatePort, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(500)) { return $false }
        $client.EndConnect($async)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

function Get-PowerBIPort {
    $localAppData = Get-LocalAppDataPath
    $candidates = @(
        (Join-Path $localAppData 'Microsoft\Power BI Desktop\AnalysisServicesWorkspaces\*\Data\msmdsrv.port.txt'),
        (Join-Path $localAppData 'Microsoft\Power BI Desktop Store App\AnalysisServicesWorkspaces\*\Data\msmdsrv.port.txt')
    )
    $portFiles = @()
    foreach ($pattern in $candidates) {
        $portFiles += Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    }
    if (-not $portFiles) { return $null }

    $reachable = @()
    foreach ($file in $portFiles) {
        $candidatePort = Read-PowerBIPortFile -Path $file.FullName
        if ($candidatePort -and (Test-LocalPort -CandidatePort $candidatePort)) {
            $reachable += [PSCustomObject]@{
                Port = $candidatePort
                Path = $file.FullName
                LastWriteTime = $file.LastWriteTime
            }
        }
    }

    if (-not $reachable) { return $null }

    if ($reachable.Count -gt 1) {
        $details = ($reachable | Sort-Object LastWriteTime -Descending | ForEach-Object {
            "localhost:$($_.Port) from $($_.Path)"
        }) -join "`n  "
        [Console]::Error.WriteLine("Multiple active Power BI Desktop workspaces were detected. Rerun with -Port for the target instance:`n  $details")
        exit 5
    }

    return $reachable[0].Port
}

function Invoke-BpaRun {
    param(
        [string]$RulesUrl,
        [switch]$AllowCustomRulesUrl,
        [int]$Port,
        [string]$Database,
        [switch]$InstallTabularEditor
    )

    # Step 1 — Resolve Tabular Editor 2 (install if missing)
    $installScript = Join-Path $here 'install-tabular-editor.ps1'
    $installArgs = @()
    if ($InstallTabularEditor) {
        $installArgs += '-Install'
    }
    $exePath = & $installScript @installArgs
    if (-not $exePath -or -not (Test-Path $exePath)) {
        [Console]::Error.WriteLine("Could not resolve TabularEditor.exe. If the user approved installation, rerun with -InstallTabularEditor.")
        exit 1
    }

    # Step 2 — Detect the live Power BI Desktop AS port (if not provided)
    if ($Port -eq 0) {
        $detected = Get-PowerBIPort
        if (-not $detected) {
            [Console]::Error.WriteLine("No active Power BI Desktop workspace was detected. Is the .pbip open?")
            exit 2
        }
        $Port = [int]$detected
    }

    Write-Host "Connecting to Power BI Desktop at localhost:$Port" -ForegroundColor Cyan

    # Step 3 — Download (or cache) the BPA rules JSON
    Assert-SafeRulesUri -Uri $RulesUrl -AllowCustomRulesUrl:$AllowCustomRulesUrl

    $cacheRoot = Join-Path (Join-Path (Get-LocalAppDataPath) 'BI Superpowers') 'Cache'
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
    $rulesPath = Get-BpaRulesCachePath -RulesUrl $RulesUrl -CacheRoot $cacheRoot
    $cacheStale = -not (Test-Path $rulesPath) -or `
                  ((Get-Item $rulesPath).LastWriteTime -lt (Get-Date).AddDays(-7))

    if ($cacheStale) {
        Write-Host "Downloading BPA rules from $RulesUrl..." -ForegroundColor Cyan
        try {
            $headers = @{ 'User-Agent' = 'bi-superpowers-bpa' }
            if ($env:GITHUB_TOKEN) {
                $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
            }
            Invoke-WebRequest -Uri $RulesUrl -OutFile $rulesPath -UseBasicParsing -Headers $headers
        }
        catch {
            [Console]::Error.WriteLine("Failed to download BPA rules: $($_.Exception.Message). If this is a rate-limit error, set GITHUB_TOKEN and rerun.")
            exit 3
        }
    }

    # Step 4 — Run TE2 with -A (Analyze). TE2 connects to localhost:port and
    # auto-discovers the database when only one is present (always the case for
    # a Power BI Desktop instance).
    $server = "localhost:$Port"
    $argsList = @($server)
    if ($Database) { $argsList += $Database }
    $argsList += @('-A', $rulesPath)

    Write-Host "Running: $exePath $($argsList -join ' ')" -ForegroundColor DarkGray
    # Capture stdout and stderr separately. TE2 writes BPA findings (and a
    # non-zero exit) to stdout for rule violations — the *normal* audit case —
    # while connection/CLI failures go to stderr. Merging them with 2>&1 would
    # let a failure's stderr text masquerade as findings and exit 0.
    $stderrFile = [System.IO.Path]::GetTempFileName()
    try {
        $output = & $exePath @argsList 2>$stderrFile
        $exitCode = $LASTEXITCODE
        $stderr = Get-Content -LiteralPath $stderrFile -Raw -ErrorAction SilentlyContinue
    }
    finally {
        Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
    }

    # No findings on stdout AND a non-zero exit = infrastructure failure (bad
    # port, unsupported -A, failed AS connection). Now that stderr is captured
    # separately, an empty stdout reliably means "no findings", so a clean
    # zero-finding audit (exit 0) is never treated as a failure even if TE2
    # emitted an incidental warning to stderr (surfaced as a diagnostic below).
    if ([string]::IsNullOrWhiteSpace($output) -and $exitCode -ne 0) {
        $detail = if ([string]::IsNullOrWhiteSpace($stderr)) { 'no output' } else { $stderr.Trim() }
        [Console]::Error.WriteLine("TE2 failed (exit code $exitCode) connecting to localhost:$Port. $detail")
        exit 4
    }

    # Surface any stderr as a diagnostic without letting it pollute the findings.
    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        [Console]::Error.WriteLine($stderr.Trim())
    }

    Write-Output $output
    exit 0
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-BpaRun `
        -RulesUrl $RulesUrl `
        -AllowCustomRulesUrl:$AllowCustomRulesUrl `
        -Port $Port `
        -Database $Database `
        -InstallTabularEditor:$InstallTabularEditor
}
