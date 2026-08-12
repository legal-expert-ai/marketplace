# Input and schema design

## Supported input modes

### Local or attached documents

Inventory only user-selected roots. Resolve symlinks without following them outside the selected root. Use relative paths and SHA-256 checksums as stable identities. Do not upload the files unless the user explicitly requests an upload.

### Legal Expert MCP sources

Resolve a user-facing name with `list_document_folders` and `list_document_bundles`, then load the exact manifest with `get_document_bundle`. Preserve tenant-scoped `bundle_id`, `file_id`, file role/label, version, and returned citation anchors. Retrieve bounded content with `read_document_file`; use `search_document_contents` only for discovery and retain its precise returned locator. Never infer access from a caller-supplied organization or user ID.

### User-provided template

Inspect before editing:

- sheets and used ranges;
- headers and representative records;
- formulas and named ranges;
- tables, filters, validation, conditional formatting, and merged cells;
- hidden sheets/rows/columns and protection;
- locale-sensitive dates, currencies, and units.

Map requested fields to existing columns. Add columns or sheets only when the template cannot represent a required auditable value.

### New schema

Define a schema row for each output column:

| Field | Meaning |
| --- | --- |
| `column_name` | Stable machine-safe name |
| `display_label` | User-facing workbook label |
| `question` | Exact extraction question |
| `data_type` | text, boolean, date, number, currency, enum, list, or citation |
| `allowed_values` | Closed vocabulary when applicable |
| `normalization` | Date, amount, party, or clause normalization rule |
| `row_granularity` | What creates a distinct row |
| `evidence_required` | Required locator and source kind |
| `missing_rule` | Blank plus exception code, or explicit not-applicable |

Freeze a `schema_version` and include it in every worker assignment and the Run Summary.

## Logical grouping

Prefer explicit user grouping. Otherwise use principal-instrument references, contract number, parties, title, dates, filenames, and cross-references. Keep amendments and annexes with the instrument they modify. Flag a group as incomplete when the main instrument is missing instead of guessing its terms.
