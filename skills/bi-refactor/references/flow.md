# BI Refactor Flow

```mermaid
flowchart TD
    A["User invokes /bi-refactor"] --> B{"Existing PBIP or PBIX?"}
    B -->|"Loose PBIX"| C["Explain PBIP and guide Save as -> PBIP in Desktop"]
    B -->|"PBIP"| D["Default to Refactor asistido por template"]
    C --> D
    D --> E{"User explicitly chose sin template?"}
    E -->|"No"| F["Use base-template as benchmark only"]
    E -->|"Yes"| G["Use current project only"]
    F --> H["Verify backup or commit"]
    G --> H
    H --> I["Diagnose model and report bindings"]
    I --> J["Apply semantic changes with exact MCP operations"]
    J --> K["Preserve report topology lock"]
    K --> L["No safe report rebind command ships today"]
    L --> N["Hand off manual Desktop rebind"]
    N --> O["Validate persistence and no .Report A/D/R"]
    O --> P["Close with changed/remaining work"]
```

## Notes

- `base-template` is a benchmark, not a file to paste over the project.
- PBIP + Git gives text diffs, rollback, reviews, and team workflow.
- The report topology lock is stricter than convenience: never rebuild the user's report as a shortcut.
