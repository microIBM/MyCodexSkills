#requires -Version 7.0

param(
    [string] $TemplateRoot = 'templates/base-template',

    [Parameter(Mandatory = $true)]
    [string] $OverlayPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Pin stdout to UTF-8 so the blueprint JSON keeps "Métricas"/"Descripción" intact
# when Node decodes the pipe as UTF-8, regardless of the host console codepage.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Read-Overlay {
    param([string] $Path)
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
}

function Get-MetricsTmdlPath {
    param([string] $Root)
    $path = Join-Path $Root 'base-template.SemanticModel/definition/tables/Métricas.tmdl'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Métricas.tmdl not found under $Root"
    }
    return $path
}

function Convert-MetricRow {
    param(
        [string] $Row,
        [string[]] $Columns
    )

    # Assumes the Métricas catalog uses uppercase TRUE/FALSE booleans and no
    # embedded/doubled quotes ("") in text cells; a violating edit throws the
    # "Unexpected ... row shape" error below rather than silently mis-parsing.
    # Use a private name, not the automatic $matches variable (which any later
    # -match would silently overwrite).
    $tokenMatches = [regex]::Matches($Row, '"([^"]*)"|TRUE|FALSE|[-]?\d+(?:\.\d+)?')
    $values = @($tokenMatches | ForEach-Object { $_.Value.Trim('"') })
    if ($values.Count -ne $Columns.Count) {
        throw "Unexpected Métricas DATATABLE row shape: $Row"
    }

    $rowByColumn = @{}
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $rowByColumn[$Columns[$i]] = $values[$i]
    }

    return [ordered]@{
        metricName = $rowByColumn['Métrica']
        format = $rowByColumn['Formato']
        formatType = $rowByColumn['Tipo de formato']
        trendDirection = $rowByColumn['Tendencia']
        description = $rowByColumn['Descripción']
    }
}

function Read-BaseTemplateMetrics {
    param([string] $Path)

    $content = Get-Content -LiteralPath $Path -Raw
    $table = [regex]::Match(
        $content,
        'DATATABLE\s*\((?<header>[\s\S]*?),\s*\{(?<rows>[\s\S]*?)\n\s*\}\s*\)\s*$'
    )
    if (-not $table.Success) {
        throw 'Could not locate the Métricas DATATABLE rows.'
    }

    $columns = @(
        [regex]::Matches($table.Groups['header'].Value, '"([^"]+)"\s*,\s*(?:STRING|INTEGER|BOOLEAN)') |
            ForEach-Object { $_.Groups[1].Value }
    )
    if ($columns.Count -eq 0) {
        throw 'Could not locate the Métricas DATATABLE columns.'
    }

    $rowOptions = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $rows = [regex]::Matches($table.Groups['rows'].Value, '\{\s*(?<row>[^{}]*?)\s*\}', $rowOptions)
    return @($rows | ForEach-Object { Convert-MetricRow -Row $_.Groups['row'].Value -Columns $columns })
}

$overlay = Read-Overlay -Path $OverlayPath
$metrics = Read-BaseTemplateMetrics -Path (Get-MetricsTmdlPath -Root $TemplateRoot)
$metricByName = @{}
foreach ($metric in $metrics) {
    $metricByName[$metric.metricName] = $metric
}

$goals = @()
foreach ($goal in $overlay.goals) {
    if (-not $goal.scorecardEnabled) {
        continue
    }
    if (-not $metricByName.ContainsKey($goal.metricName)) {
        throw "Overlay references metric not found in base-template: $($goal.metricName)"
    }

    $metric = $metricByName[$goal.metricName]
    $goals += [ordered]@{
        metricName = $goal.metricName
        goalName = $goal.goalName
        description = $metric.description
        format = $metric.format
        formatType = $metric.formatType
        trendDirection = $metric.trendDirection
        owner = $goal.owner
        cadence = $goal.cadence
        startDate = $goal.startDate
        dueDate = $goal.dueDate
        target = $goal.target
        statusRulePreset = $goal.statusRulePreset
    }
}

[ordered]@{
    sourceTemplate = 'templates/base-template/base-template.pbip'
    metricsTable = 'Métricas'
    scorecardName = $overlay.scorecardName
    goals = $goals
} | ConvertTo-Json -Depth 100
