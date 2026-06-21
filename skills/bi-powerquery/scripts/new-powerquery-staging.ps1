[CmdletBinding(DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory = $true)]
    [string]$TableName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Inline')]
    [string]$SourceExpression,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [string]$SourceExpressionPath,

    [string]$RealQueryName,

    [string[]]$RequiredColumns,

    [string[]]$ProjectionColumns,

    [string]$ColumnTypesJson,

    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
# Pin stdout to UTF-8 so generated M with accented column names round-trips when
# the caller (Node/MCP) decodes the pipe as UTF-8, regardless of console codepage.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function New-TableContract {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Columns,

        [hashtable]$ColumnTypes = @{}
    )

    $types = @()
    foreach ($column in $Columns) {
        $typeExpression = if ($ColumnTypes.ContainsKey($column)) { $ColumnTypes[$column] } else { 'type text' }
        $types += ,@($column, $typeExpression)
    }

    return [ordered]@{
        RequiredColumns = $Columns
        Types = $types
        Projection = @('Data') + $Columns
    }
}

function Get-TableContract {
    param([string]$Name)

    $types = @{
        'Fecha' = 'type date'
        'Cantidad' = 'Int64.Type'
        'Precio Unitario' = 'type number'
        'Costo Unitario' = 'type number'
        'Venta Bruta' = 'type number'
        'Costo Total' = 'type number'
        'Venta Bruta Base' = 'type number'
        'Costo Total Base' = 'type number'
        'Leads' = 'Int64.Type'
        'MQLs' = 'Int64.Type'
        'Clientes ganados' = 'Int64.Type'
        'Costo Base' = 'Int64.Type'
        'Ventas Atribuidas Base' = 'Int64.Type'
        'Importe Potencial Base' = 'Int64.Type'
        'Probabilidad' = 'type number'
        'Clientes Inicio' = 'Int64.Type'
        'Clientes Perdidos' = 'Int64.Type'
        'NPS' = 'Int64.Type'
        'Reclamos' = 'Int64.Type'
        'Tiempo Respuesta Horas' = 'type number'
        'Entregas' = 'Int64.Type'
        'Entregas A Tiempo' = 'Int64.Type'
        'Órdenes' = 'Int64.Type'
        'Órdenes Completadas' = 'Int64.Type'
        'Backlog' = 'Int64.Type'
        'Tiempo Ciclo Días' = 'Int64.Type'
        'SLA Cumplido' = 'Int64.Type'
        'Retrabajos' = 'Int64.Type'
        'Horas Usadas' = 'Int64.Type'
        'Horas Disponibles' = 'Int64.Type'
        'Servicios Adjuntos' = 'Int64.Type'
        'Importe Base' = 'Int64.Type'
        'Importe Presupuesto Base' = 'Int64.Type'
        'Unidades Devueltas' = 'Int64.Type'
        'Horas Planificadas' = 'Int64.Type'
        'Horas Trabajadas' = 'Int64.Type'
        'Horas Facturables' = 'Int64.Type'
        'Horas Ausentes' = 'Int64.Type'
        'Headcount' = 'Int64.Type'
        'Costo Laboral Base' = 'Int64.Type'
        'Bajas' = 'Int64.Type'
        'Avance' = 'type number'
        'Ingresos Base' = 'Int64.Type'
        'Costos Base' = 'Int64.Type'
        'Presupuesto Base' = 'Int64.Type'
        'Tareas' = 'Int64.Type'
        'Tareas Vencidas' = 'Int64.Type'
        'Horas' = 'Int64.Type'
    }

    switch ($Name) {
        'Clientes' { return New-TableContract -Columns @('ClienteId', 'Cliente', 'Segmento', 'Pais') -ColumnTypes $types }
        'Productos' { return New-TableContract -Columns @('ProductoId', 'Producto', 'Categoria', 'Subcategoria') -ColumnTypes $types }
        'Canales' { return New-TableContract -Columns @('CanalId', 'Canal', 'Tipo de canal') -ColumnTypes $types }
        'Servicios' { return New-TableContract -Columns @('ServicioId', 'Servicio', 'Línea servicio', 'Modalidad') -ColumnTypes $types }
        'Proyectos' { return New-TableContract -Columns @('ProyectoId', 'Proyecto', 'Tipo proyecto', 'Estado proyecto') -ColumnTypes $types }
        'Equipos' { return New-TableContract -Columns @('EquipoId', 'Equipo', 'Área equipo', 'Seniority') -ColumnTypes $types }
        'Campañas' { return New-TableContract -Columns @('CampañaId', 'Campaña', 'Canal marketing', 'Objetivo campaña') -ColumnTypes $types }
        'Ventas' { return New-TableContract -Columns @('VentaId', 'Fecha', 'ProductoId', 'ClienteId', 'CanalId', 'Moneda', 'Cantidad', 'Precio Unitario', 'Costo Unitario', 'Venta Bruta', 'Costo Total', 'Venta Bruta Base', 'Costo Total Base') -ColumnTypes $types }
        'Oportunidades' { return New-TableContract -Columns @('OportunidadId', 'Fecha', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'Estado', 'Importe Potencial Base', 'Probabilidad') -ColumnTypes $types }
        'Leads' { return New-TableContract -Columns @('LeadBatchId', 'Fecha', 'CampañaId', 'CanalId', 'ClienteId', 'Leads', 'MQLs', 'Clientes ganados', 'Costo Base', 'Ventas Atribuidas Base') -ColumnTypes $types }
        'Interacciones clientes' { return New-TableContract -Columns @('InteraccionId', 'Fecha', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'Clientes Inicio', 'Clientes Perdidos', 'NPS', 'Reclamos', 'Tiempo Respuesta Horas') -ColumnTypes $types }
        'Entregas' { return New-TableContract -Columns @('EntregaId', 'Fecha', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'Entregas', 'Entregas A Tiempo') -ColumnTypes $types }
        'Órdenes servicio' { return New-TableContract -Columns @('OrdenServicioId', 'Fecha', 'ClienteId', 'ProductoId', 'ServicioId', 'EquipoId', 'Órdenes', 'Órdenes Completadas', 'Backlog', 'Tiempo Ciclo Días', 'SLA Cumplido', 'Retrabajos', 'Horas Usadas', 'Horas Disponibles', 'Servicios Adjuntos') -ColumnTypes $types }
        'Movimientos financieros' { return New-TableContract -Columns @('MovimientoId', 'Fecha', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'ProyectoId', 'EquipoId', 'Tipo movimiento', 'Importe Base') -ColumnTypes $types }
        'Presupuesto' { return New-TableContract -Columns @('PresupuestoId', 'Fecha', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'ProyectoId', 'EquipoId', 'Área presupuesto', 'Importe Presupuesto Base') -ColumnTypes $types }
        'Devoluciones' { return New-TableContract -Columns @('DevolucionId', 'Fecha', 'ClienteId', 'CanalId', 'ProductoId', 'Unidades Devueltas') -ColumnTypes $types }
        'Horas' { return New-TableContract -Columns @('HoraId', 'Fecha', 'EquipoId', 'ProyectoId', 'ServicioId', 'Horas Planificadas', 'Horas Trabajadas', 'Horas Facturables', 'Horas Disponibles', 'Horas Ausentes') -ColumnTypes $types }
        'Nómina' { return New-TableContract -Columns @('NominaId', 'Fecha', 'EquipoId', 'ProyectoId', 'ServicioId', 'Headcount', 'Costo Laboral Base', 'Bajas') -ColumnTypes $types }
        'Ejecución proyectos' { return New-TableContract -Columns @('EjecucionProyectoId', 'Fecha', 'ProyectoId', 'ClienteId', 'ServicioId', 'EquipoId', 'Estado ejecución', 'Avance', 'Ingresos Base', 'Costos Base', 'Presupuesto Base') -ColumnTypes $types }
        'Tareas proyecto' { return New-TableContract -Columns @('TareaProyectoId', 'Fecha', 'ProyectoId', 'EquipoId', 'Tareas', 'Tareas Vencidas', 'Horas') -ColumnTypes $types }
    }
}

function Assert-SafeMType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TypeExpression,

        [Parameter(Mandatory = $true)]
        [string]$ColumnName
    )

    $allowed = @(
        'type text',
        'type nullable text',
        'type number',
        'type nullable number',
        'type date',
        'type nullable date',
        'type datetime',
        'type nullable datetime',
        'type logical',
        'type nullable logical',
        'Int64.Type',
        'Currency.Type',
        'Percentage.Type'
    )

    if ($allowed -notcontains $TypeExpression) {
        throw "ColumnTypesJson contains unsupported M type '$TypeExpression' for column '$ColumnName'."
    }
}

function Convert-ColumnList {
    param([string[]]$Items)

    $result = @()
    foreach ($item in $Items) {
        if ([string]::IsNullOrWhiteSpace($item)) {
            continue
        }

        foreach ($part in ($item -split ',')) {
            $trimmed = $part.Trim()
            if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                $result += $trimmed
            }
        }
    }

    return $result
}

function New-GeneratedTableContract {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string[]]$RequiredColumns,

        [string[]]$ProjectionColumns,

        [string]$ColumnTypesJson
    )

    $normalizedRequiredColumns = Convert-ColumnList -Items $RequiredColumns
    $normalizedProjectionColumns = Convert-ColumnList -Items $ProjectionColumns

    if ($null -eq $normalizedRequiredColumns -or $normalizedRequiredColumns.Count -eq 0) {
        throw "TableName '$Name' is not a bundled base-template table. Provide -RequiredColumns for generated-domain tables."
    }

    foreach ($column in $normalizedRequiredColumns) {
        if ([string]::IsNullOrWhiteSpace($column)) {
            throw 'RequiredColumns cannot contain blank values.'
        }
    }

    $typeMap = @{}
    if (-not [string]::IsNullOrWhiteSpace($ColumnTypesJson)) {
        $parsed = ConvertFrom-Json -InputObject $ColumnTypesJson
        foreach ($property in $parsed.PSObject.Properties) {
            $typeExpression = [string]$property.Value
            Assert-SafeMType -TypeExpression $typeExpression -ColumnName $property.Name
            $typeMap[$property.Name] = $typeExpression
        }
    }

    $types = @()
    foreach ($column in $normalizedRequiredColumns) {
        $typeExpression = if ($typeMap.ContainsKey($column)) { $typeMap[$column] } else { 'type text' }
        $types += ,@($column, $typeExpression)
    }

    $projection = if ($null -eq $normalizedProjectionColumns -or $normalizedProjectionColumns.Count -eq 0) {
        @('Data') + $normalizedRequiredColumns
    } elseif ($normalizedProjectionColumns -contains 'Data') {
        $normalizedProjectionColumns
    } else {
        @('Data') + $normalizedProjectionColumns
    }

    return [ordered]@{
        RequiredColumns = $normalizedRequiredColumns
        Types = $types
        Projection = $projection
    }
}

function Format-MTextList {
    param([string[]]$Items)
    $quoted = $Items | ForEach-Object { '"' + ($_ -replace '"', '""') + '"' }
    return '{' + ($quoted -join ', ') + '}'
}

function Format-MTypePairs {
    param([array]$Pairs)
    $formatted = foreach ($pair in $Pairs) {
        '{"' + ($pair[0] -replace '"', '""') + '", ' + $pair[1] + '}'
    }
    return '{' + ($formatted -join ', ') + '}'
}

function Assert-SafePowerQueryName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$ParameterName = 'Name'
    )

    if ($Name.Length -gt 80 -or $Name -notmatch '^[\p{L}][\p{L}0-9 _-]*$') {
        throw "$ParameterName contains unsafe characters. Use letters, numbers, spaces, hyphen, or underscore, starting with a letter."
    }
}

function Format-MQuotedIdentifier {
    param([Parameter(Mandatory = $true)][string]$Name)
    return '#"' + ($Name -replace '"', '""') + '"'
}

function Join-SafeChildFile {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$FileName
    )

    $root = [System.IO.Path]::GetFullPath($Directory)
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $root $FileName))
    $rootWithSeparator = $root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar

    if (-not $candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Output path escaped OutputDirectory: $FileName"
    }

    return $candidate
}

function Assert-SafeOutputDirectory {
    param([Parameter(Mandatory = $true)][string]$Directory)

    $fullPath = [System.IO.Path]::GetFullPath($Directory)
    $segments = $fullPath -split '[\\/]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    foreach ($segment in $segments) {
        if ($segment.EndsWith('.SemanticModel', [System.StringComparison]::OrdinalIgnoreCase) -or
            $segment.EndsWith('.Report', [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($segment, 'pbip-files', [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($segment, '.pbi', [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($segment, 'DAXQueries', [System.StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($segment, 'TMDLScripts', [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "OutputDirectory must be outside Power BI project artifact folders. Use a scratch folder such as '.\powerquery-output'."
        }
    }
}

if ($PSCmdlet.ParameterSetName -eq 'File') {
    if (-not (Test-Path -LiteralPath $SourceExpressionPath)) {
        throw "SourceExpressionPath not found: $SourceExpressionPath"
    }
    $SourceExpression = (Get-Content -LiteralPath $SourceExpressionPath -Raw).Trim()
}

if ([string]::IsNullOrWhiteSpace($RealQueryName)) {
    $RealQueryName = "${TableName}_Real"
}
Assert-SafePowerQueryName -Name $TableName -ParameterName 'TableName'
Assert-SafePowerQueryName -Name $RealQueryName -ParameterName 'RealQueryName'

$contract = Get-TableContract -Name $TableName
if ($null -eq $contract) {
    $contract = New-GeneratedTableContract -Name $TableName -RequiredColumns $RequiredColumns -ProjectionColumns $ProjectionColumns -ColumnTypesJson $ColumnTypesJson
}
$requiredColumns = Format-MTextList -Items $contract.RequiredColumns
$typePairs = Format-MTypePairs -Pairs $contract.Types
$projection = Format-MTextList -Items $contract.Projection

# SECURITY: $SourceExpression is inserted verbatim as the M `Source` step and
# runs as code on every model refresh — it is validated only as a connector
# expression by the caller, not sandboxed. Only ever pass a connection
# expression the user authored or approved; never agent-summarized or untrusted
# source text (see the bi-powerquery SKILL.md "untrusted source" rule).
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('let')
$lines.Add("    Source = $SourceExpression,")
$lines.Add("    RequiredColumns = $requiredColumns,")
$lines.Add('    MissingColumns = List.Difference(RequiredColumns, Table.ColumnNames(Source)),')
$lines.Add('    AssertRequiredColumns = if List.Count(MissingColumns) = 0 then Source else error Error.Record("MissingColumns", "Source is missing required columns.", MissingColumns),')
$lines.Add("    Typed = Table.TransformColumnTypes(AssertRequiredColumns, $typePairs, `"en-US`"),")
$lines.Add('    AddData = if Table.HasColumns(Typed, "Data") then Table.TransformColumns(Typed, {{"Data", each "Real", type text}}) else Table.AddColumn(Typed, "Data", each "Real", type text),')

$lines.Add("    Result = Table.SelectColumns(AddData, $projection)")
$lines.Add('in')
$lines.Add('    Result')
$realQueryM = $lines -join [Environment]::NewLine

$realQueryRef = Format-MQuotedIdentifier -Name $RealQueryName
$loadedAppendM = @"
let
    Demo = ExistingDemoResult,
    Real = $realQueryRef,
    Result = Table.Combine({Demo, Real})
in
    Result
"@

$writtenFiles = @()
if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
    Assert-SafeOutputDirectory -Directory $OutputDirectory
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    $realPath = Join-SafeChildFile -Directory $OutputDirectory -FileName "$RealQueryName.m"
    $appendPath = Join-SafeChildFile -Directory $OutputDirectory -FileName "${TableName}_append-template.m"
    Set-Content -LiteralPath $realPath -Value $realQueryM -Encoding UTF8NoBOM
    Set-Content -LiteralPath $appendPath -Value $loadedAppendM -Encoding UTF8NoBOM
    $writtenFiles = @($realPath, $appendPath)
}

[ordered]@{
    success = $true
    tableName = $TableName
    realQueryName = $RealQueryName
    requiredColumns = $contract.RequiredColumns
    generatedColumns = @('Data')
    realQueryM = $realQueryM
    loadedAppendM = $loadedAppendM
    writtenFiles = $writtenFiles
} | ConvertTo-Json -Depth 8

