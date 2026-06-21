[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TemplateRoot
)

$ErrorActionPreference = 'Stop'
# Pin stdout to UTF-8 so validation JSON with accented paths (for example C:\Users\Jose)
# round-trips when the caller (Node/MCP) decodes the pipe as UTF-8.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Resolve-DefinitionPath {
    param([string]$Root)

    $candidates = @(
        (Join-Path $Root 'base-template.SemanticModel\definition'),
        (Join-Path $Root 'definition'),
        $Root
    )

    foreach ($candidate in $candidates) {
        if ((Test-Path -LiteralPath (Join-Path $candidate 'relationships.tmdl')) -and
            (Test-Path -LiteralPath (Join-Path $candidate 'tables'))) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Could not find a semantic model definition folder under: $Root"
}

function Add-Error {
    param(
        [System.Collections.Generic.List[object]]$Errors,
        [string]$Table,
        [string]$Message
    )

    $Errors.Add([ordered]@{ table = $Table; message = $Message })
}

function Test-Column {
    param(
        [string]$Text,
        [string]$Table,
        [string]$Column,
        [bool]$RequireHidden,
        [string]$DataType,
        [System.Collections.Generic.List[object]]$Errors
    )

    $escaped = [regex]::Escape($Column)
    $columnPattern = "(?ms)^\tcolumn '?$escaped'?\r?\n(?<block>.*?)(?=\r?\n\t(?:column|partition|hierarchy|measure|annotation|///)|\z)"
    $match = [regex]::Match($Text, $columnPattern)
    if (-not $match.Success) {
        $anyColumnPattern = "(?ms)^\tcolumn '?[^'\r\n]+'?\r?\n(?<block>.*?)(?=\r?\n\t(?:column|partition|hierarchy|measure|annotation|///)|\z)"
        foreach ($candidate in [regex]::Matches($Text, $anyColumnPattern)) {
            if ($candidate.Groups['block'].Value -match "sourceColumn: $escaped(\r?\n|$)") {
                $match = $candidate
                break
            }
        }
    }
    if (-not $match.Success) {
        Add-Error -Errors $Errors -Table $Table -Message "Missing column $Column"
        return
    }

    $block = $match.Groups['block'].Value
    if ($block -notmatch "sourceColumn: $escaped(\r?\n|$)") {
        Add-Error -Errors $Errors -Table $Table -Message "Column $Column is missing sourceColumn $Column"
    }

    if ($RequireHidden -and $block -notmatch '(^|\r?\n)\t\tisHidden(\r?\n|$)') {
        Add-Error -Errors $Errors -Table $Table -Message "Column $Column should be hidden"
    }

    if (-not [string]::IsNullOrWhiteSpace($DataType) -and $block -notmatch "dataType: $DataType") {
        Add-Error -Errors $Errors -Table $Table -Message "Column $Column should have dataType $DataType"
    }
}

$definitionPath = Resolve-DefinitionPath -Root $TemplateRoot
$tablesPath = Join-Path $definitionPath 'tables'
$errors = [System.Collections.Generic.List[object]]::new()
$campanas = 'Campa' + [char]0x00F1 + 'as'
$campanaId = 'Campa' + [char]0x00F1 + 'aId'
$ordenesServicio = [char]0x00D3 + 'rdenes servicio'
$nomina = 'N' + [char]0x00F3 + 'mina'
$ejecucionProyectos = 'Ejecuci' + [char]0x00F3 + 'n proyectos'
$appendableTables = @(
    'Clientes',
    'Productos',
    'Canales',
    'Servicios',
    'Proyectos',
    'Equipos',
    $campanas,
    'Ventas',
    'Oportunidades',
    'Leads',
    'Interacciones clientes',
    'Entregas',
    $ordenesServicio,
    'Movimientos financieros',
    'Presupuesto',
    'Devoluciones',
    'Horas',
    $nomina,
    $ejecucionProyectos,
    'Tareas proyecto'
)
$idColumns = [ordered]@{
    Clientes = @('ClienteId')
    Productos = @('ProductoId')
    Canales = @('CanalId')
    Servicios = @('ServicioId')
    Proyectos = @('ProyectoId')
    Equipos = @('EquipoId')
    Ventas = @('VentaId', 'ProductoId', 'ClienteId', 'CanalId')
    Oportunidades = @('OportunidadId', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId')
    Leads = @('LeadBatchId', $campanaId, 'CanalId', 'ClienteId')
    'Interacciones clientes' = @('InteraccionId', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId')
    Entregas = @('EntregaId', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId')
    'Movimientos financieros' = @('MovimientoId', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'ProyectoId', 'EquipoId')
    Presupuesto = @('PresupuestoId', 'ClienteId', 'CanalId', 'ProductoId', 'ServicioId', 'ProyectoId', 'EquipoId')
    Devoluciones = @('DevolucionId', 'ClienteId', 'CanalId', 'ProductoId')
    Horas = @('HoraId', 'EquipoId', 'ProyectoId', 'ServicioId')
    'Tareas proyecto' = @('TareaProyectoId', 'ProyectoId', 'EquipoId')
}
$idColumns[$campanas] = @($campanaId)
$idColumns[$ordenesServicio] = @('OrdenServicioId', 'ClienteId', 'ProductoId', 'ServicioId', 'EquipoId')
$idColumns[$nomina] = @('NominaId', 'EquipoId', 'ProyectoId', 'ServicioId')
$idColumns[$ejecucionProyectos] = @('EjecucionProyectoId', 'ProyectoId', 'ClienteId', 'ServicioId', 'EquipoId')

foreach ($table in $appendableTables) {
    $tablePath = Join-Path $tablesPath "$table.tmdl"
    if (-not (Test-Path -LiteralPath $tablePath)) {
        Add-Error -Errors $errors -Table $table -Message "Missing table TMDL file"
        continue
    }

    $text = Get-Content -LiteralPath $tablePath -Raw -Encoding UTF8
    Test-Column -Text $text -Table $table -Column 'Data' -RequireHidden:$false -DataType 'string' -Errors $errors

    foreach ($column in $idColumns[$table]) {
        Test-Column -Text $text -Table $table -Column $column -RequireHidden:$true -DataType 'string' -Errors $errors
    }

    if ($text -match 'DataKey') {
        Add-Error -Errors $errors -Table $table -Message 'Unexpected DataKey column or expression found'
    }

    $usesEntityCodeFunction = $text -match 'EntityCode\s*=\s*\(entity as text, n as number\)'
    $usesEntityCodeCall = $text -match 'EntityCode\("[A-Za-z]+",'
    $usesEntityLiteralId = $text -match '"(?:Cliente|Producto|Canal|Servicio|Proyecto|Equipo|Campana)A[0-9]{2}[A-Z]"'
    $usesExtensibleEntityCode = $text -match 'ToLetters\s*=\s*\(value as number\) as text' -and
        $text -match '@ToLetters\(Number\.IntegerDivide\(Current, 26\) - 1\)' -and
        $text -match 'BlockCode = ToLetters\(Number\.IntegerDivide\(CleanNumber - 1, 100\)\)'
    $usesOldInlineDemoId = $text -match '"Demo" & Text\.PadStart\(Text\.From\(\['
    $usesOldHelperDemoId = $text -match 'DemoId\([^,\r\n]+,\s*9\)'
    $usesOldLiteralDemoId = $text -match '"Demo[0-9]{9}"'

    if ($usesOldInlineDemoId -or $usesOldHelperDemoId -or $usesOldLiteralDemoId) {
        Add-Error -Errors $errors -Table $table -Message 'Demo IDs should use entity-coded values such as ClienteA25D, not Demo#########'
    }

    if ($text -match 'IdDemo') {
        Add-Error -Errors $errors -Table $table -Message 'Temporary entity-code columns should use *Codigo names, not *IdDemo'
    }

    if (-not ($usesEntityCodeCall -or $usesEntityLiteralId)) {
        Add-Error -Errors $errors -Table $table -Message 'Demo IDs should use entity-coded values such as ClienteA25D'
    }

    if ($usesEntityCodeCall -and -not $usesEntityCodeFunction) {
        Add-Error -Errors $errors -Table $table -Message 'EntityCode helper calls require the local EntityCode function'
    }

    if ($usesEntityCodeFunction -and -not $usesExtensibleEntityCode) {
        Add-Error -Errors $errors -Table $table -Message 'EntityCode helper should use extensible alphabetic blocks so fact IDs stay unique past 2600 rows'
    }
}

$relationshipsPath = Join-Path $definitionPath 'relationships.tmdl'
$relationships = Get-Content -LiteralPath $relationshipsPath -Raw -Encoding UTF8
$relationshipChecks = @(
    'Ventas_ProductoId_Productos_ProductoId',
    'fromColumn: Ventas.ProductoId',
    'toColumn: Productos.ProductoId',
    'Ventas_ClienteId_Clientes_ClienteId',
    'fromColumn: Ventas.ClienteId',
    'toColumn: Clientes.ClienteId',
    'Ventas_CanalId_Canales_CanalId',
    'fromColumn: Ventas.CanalId',
    'toColumn: Canales.CanalId',
    'Oportunidades_ServicioId_Servicios_ServicioId',
    "Leads_${campanaId}_${campanas}_${campanaId}",
    'Interacciones clientes_ServicioId_Servicios_ServicioId',
    'Movimientos financieros_ProyectoId_Proyectos_ProyectoId',
    'Presupuesto_EquipoId_Equipos_EquipoId',
    'Horas_ProyectoId_Proyectos_ProyectoId',
    "${ejecucionProyectos}_ProyectoId_Proyectos_ProyectoId",
    'Tareas proyecto_EquipoId_Equipos_EquipoId'
)

foreach ($check in $relationshipChecks) {
    if (-not $relationships.Contains($check)) {
        Add-Error -Errors $errors -Table 'relationships' -Message "Missing relationship contract text: $check"
    }
}

if ($relationships -match 'DataKey') {
    Add-Error -Errors $errors -Table 'relationships' -Message 'Relationships should use original ID columns, not DataKey columns'
}

$success = $errors.Count -eq 0
$result = [ordered]@{
    success = $success
    definitionPath = $definitionPath
    appendableTables = $appendableTables
    errors = @($errors)
}

$result | ConvertTo-Json -Depth 6
if (-not $success) { exit 1 }
