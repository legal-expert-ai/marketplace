# Row and evidence contract

Each extraction result must contain:

```json
{
  "schema_version": "v1",
  "source_id": "stable-file-id-or-relative-path",
  "bundle_id": null,
  "source_version": "sha256-or-server-version",
  "row_key": "deterministic-key",
  "values": {},
  "evidence": {},
  "row_status": "complete",
  "confidence": "high",
  "review_note": null
}
```

Allowed `row_status` values are `complete`, `partial`, `conflict`, `unreadable`, and `not_applicable`. Allowed confidence values are `high`, `medium`, and `low`.

Every populated material field must have an evidence entry with:

- stable source ID and filename;
- Legal Expert bundle/file/version identifiers when applicable;
- page, paragraph, article, section, or other precise locator;
- short supporting excerpt or faithful compact paraphrase;
- `explicit` or `inferred` basis;
- confidence and reviewer note;
- stable user-accessible URL when returned by the source service.

Law evidence must additionally preserve the act/law ID, article or provision ID, applicable-on date, effective interval/status when returned, and source URL. Commentary must be labelled secondary and never presented as statutory text.

Do not accept filename-only evidence for a material result. Do not convert true missing values into zero, false, or `N/A` strings in typed columns. Use a blank typed cell plus an Exceptions record.

The long-form Evidence sheet should contain one row per populated material field. This permits a compact Results sheet while retaining an auditable chain from normalized value to source passage.
