# Legal Expert document MCP contract

Call only tools advertised by the connected server. Every tool is tenant-scoped to the authenticated creator and requires server-side Legal Expert MCP entitlement.

## Read tools

- `list_document_folders(offset=0, limit=50)` returns paginated visible folders; maximum limit 100.
- `list_document_bundles(offset=0, limit=50, folder_id?, status?)` returns creator-owned bundles. Status is `processing`, `ready`, `failed`, or `pending_deletion`; maximum limit 100.
- `get_document_bundle(bundle_id)` returns the sanitized manifest, current status/version, summary, extracted variables, analysis, visible files, and ingest-task summary.
- `read_document_file(bundle_id, file_id?, offset=0, limit=12000)` reads extracted text from a ready bundle. Maximum character limit is 20,000; follow `next_offset`. Select an explicit file ID from the bundle manifest instead of relying on the first-file default.
- `search_document_contents(query, bundle_id?, offset=0, limit=10)` searches ready extracted text and returns citation excerpts. Query length is 2–200 and maximum limit is 50.
- `list_document_events(bundle_id?, offset=0, limit=25)` returns extracted events/deadlines; maximum limit 100.
- `read_agent_task_output_content(task_id, output_id, offset=0, limit=12000)` reads visible UTF-8 output content; maximum character limit 20,000. Use `list_agent_task_outputs` and `get_agent_task_output` first.
- `read_agent_task_output_base64(task_id, output_id, byte_offset=0, byte_limit=196608)` reads any visible artifact as a bounded base64 byte chunk; maximum byte limit 262,144. It returns `filename`, `mime_type`, `encoding: "base64"`, `content_base64`, the full-file `sha256`, `total_bytes`, and `next_byte_offset`.
- `get_notification_preferences(scope="global")` returns global email/WhatsApp settings, verification state, masked phone, and consent timestamp. The scope is optional server-side for backward compatibility, but passing it keeps the remote tool visible in current Codex clients.

Read tools have `readOnlyHint: true`, `destructiveHint: false`, `idempotentHint: true`, and `openWorldHint: false`.

Choose the text reader for visible UTF-8 text and the base64 reader for binary artifacts. For binary output, follow `next_byte_offset` until it is null, concatenate decoded bytes in offset order, require stable metadata and SHA-256 across chunks, and verify the assembled artifact against the returned full-file SHA-256. Do not expose base64, storage paths, or storage URLs in chat, logs, citations, or workbook cells.

## Upload tool

`upload_document_bundle(idempotency_key, name, files, description?, folder_id?)` creates one grouped bundle and starts ingest in a single idempotent operation.

The `files` array contains 1–10 objects with exactly:

```json
{
  "filename": "contract.pdf",
  "content_base64": "<exact base64>",
  "role": "contract"
}
```

Exactly one file has role `contract`; remaining files have role `annex`. Each decoded file is at most 8 MiB and the decoded bundle total is at most 20 MiB. URLs, local paths, empty/invalid base64, path-bearing filenames, unsupported/unsafe files, and more or fewer principal contracts are rejected.

The response contains `replayed`, bundle summary, and ingest task ID/status/type. Equivalent retries reuse the same idempotency key. A reused key with different inputs returns `conflict`.

The tool has `readOnlyHint: false`, `destructiveHint: false`, `idempotentHint: true`, and `openWorldHint: false`.

## Notification tools

- `update_notification_preferences(email?, whatsapp?)` updates at least one supplied global boolean. Enabling WhatsApp requires a verified phone.
- `send_whatsapp_verification_code(phone)` accepts an explicit E.164 number and is rate-limited. It returns only sent status and a masked phone.
- `confirm_whatsapp_verification_code(code)` accepts exactly six digits. Success verifies the phone and enables the global WhatsApp channel.

These are state-changing tools. Their current annotations are non-destructive and closed-world; obtain explicit user authorization before calling them because they change account-wide preferences or send an external message.

## Stable errors

Handle `unauthorized`, `subscription_required`, `feature_required`, `credits_required`, `invalid_input`, `not_found`, `conflict`, `unsafe_file`, `upload_failed`, `output_unavailable`, `output_too_large`, `unsupported_output_type`, `phone_verification_required`, `invalid_verification_code`, and `rate_limited` without exposing stack traces, storage paths, tokens, or cross-tenant existence.
