# Workbook and QA contract

Invoke `spreadsheets:Spreadsheets` for workbook creation or editing and obey its runtime, artifact-tool, formatting, formula, rendering, export, and final-citation requirements.

## Workbook rules

- Preserve a supplied template's conventions and edit only mapped cells/ranges.
- For a new workbook, create `Results`, `Evidence`, `Exceptions`, `Data Dictionary`, and `Run Summary`.
- Store dates and numbers as typed values, not display strings.
- Put assumptions and normalization mappings in visible cells or tables.
- Use formulas for derived calculations and consistent formulas down a column.
- Use single-quoted cross-sheet references such as `='Evidence'!A2`.
- Keep headers filterable, long text bounded, and identifiers unmodified.
- Keep source URLs as plain text in dedicated cells.

## Completion gates

1. Reconcile inventory count to completed + excluded + failed sources.
2. Validate every structured extraction row before workbook insertion.
3. Confirm every material populated field has resolvable evidence.
4. Re-read all high-risk and low-confidence values; sample at least 10% of the remainder, minimum five when available.
5. Inspect key ranges with both values and formulas.
6. Scan the workbook for `#REF!`, `#DIV/0!`, `#VALUE!`, `#NAME?`, and unexpected `#N/A`.
7. Render every sheet and repair clipped headers, unreadable wrapping, blank sheets, broken tables, or content outside the visible area.
8. Export exactly one final `.xlsx` to the required output directory.

Do not mark the task complete when requested sources remain silently unprocessed or a material exception is hidden.
