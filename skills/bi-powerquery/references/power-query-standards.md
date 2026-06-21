# Power Query Standards

## Contract First

- Validate required source columns before selecting, transforming, or appending.
- Keep final column order deterministic and identical to the base-template contract.
- Fail loudly when required columns are missing. Do not create placeholder business fields silently.
- Do not use `MissingField.UseNull` or `MissingField.Ignore` in generated staging queries. Microsoft Learn documents those options as missing-column fallbacks; this workflow wants missing columns to fail because a silent null column would corrupt relationships and measures.
- Add or overwrite `Data = "Real"` inside the real staging query, not after append. If the source already has a `Data` column, replace its values with `Real` instead of keeping user-supplied source labels.

## Types

- Use `Table.TransformColumnTypes` with an explicit culture such as `"en-US"` when parsing IDs, dates, and numbers.
- Use `type text` for relationship IDs so real rows can append to the demo tables, whose IDs are entity-coded text values such as `ClienteA25D`.
- Use `Int64.Type` for counts.
- Use `type number` for monetary/decimal values.
- For dates, match the `Calendario` key type **exactly** and strip any time component (e.g. `Date.From([Fecha])` or `type date`). A `datetime` carrying a non-midnight time silently fails to match `Calendario[Fecha]` — the engine compares the full datetime, so those rows won't join and time-intelligence goes blank/wrong.

## Query Shape

Recommended real staging shape:

```powerquery
let
    Source = ...,
    RequiredColumns = {...},
    MissingColumns = List.Difference(RequiredColumns, Table.ColumnNames(Source)),
    AssertRequiredColumns = if List.Count(MissingColumns) = 0 then Source else error Error.Record("MissingColumns", "Source is missing required columns.", MissingColumns),
    Typed = Table.TransformColumnTypes(AssertRequiredColumns, {...}, "en-US"),
    AddData = if Table.HasColumns(Typed, "Data") then Table.TransformColumns(Typed, {{"Data", each "Real", type text}}) else Table.AddColumn(Typed, "Data", each "Real", type text),
    Result = Table.SelectColumns(AddData, {...})
in
    Result
```

## MCP Authoring Contract

PBIP/TMDL files are read-only snapshots. Use them to inspect the current model,
compare output, and validate the saved result; do not edit them directly when a
live Power BI Desktop model is open.

Live Power Query changes must go through Power BI Modeling MCP:

- Use `query_group_operations` to create or reuse a helper query group.
- Use `named_expression_operations` to create or update unloaded `*_Real` M
  staging queries.
- Use `partition_operations` to update the loaded table partition that appends
  Demo + Real.
- Refresh data from **Power BI Desktop** (`Inicio ▶ Actualizar`, or `Aplicar
  cambios` when Power Query has pending changes). Microsoft does not support
  processing/refresh commands against a model open in Desktop, so do not try to
  refresh data through the MCP — author metadata via MCP, then let Desktop load
  the data.
- Save Power BI Desktop before claiming persistence.
- Use `database_operations` / `ExportToTmdlFolder` only after save/export to
  inspect and validate the snapshot Desktop wrote.

If the MCP surface cannot author the required object, guide the user through
Power BI Desktop for that step. Do not patch `.tmdl`, `.SemanticModel/**`, or
partition files as a workaround.

## Refresh Hygiene

- Keep `*_Real` staging queries unloaded after they feed the loaded template table.
- Keep credentials and privacy levels explicit. Do not mix local files, web APIs, and organizational sources casually in the same query.
- Preserve query folding for SQL and Fabric sources by pushing filters and type operations as close to the source as possible.
- Avoid hard-coded local user paths in reusable skill output; parameterize paths or ask the user for a project-local location.
- Write generated `.m` snippets only to scratch folders such as `.\powerquery-output`; never place them inside `pbip-files/`, `*.SemanticModel`, `*.Report`, `.pbi`, `DAXQueries`, or `TMDLScripts`. Those locations are Power BI project artifacts, not agent scratch space.

## Agent Behavior

- Explain the Demo/Real split while editing so the user understands why `Data` exists.
- Summarize generated M and validation results; only paste full M when the user asks.
- Use Power BI Modeling MCP for live semantic-model writes and Desktop save/export for persistence.
