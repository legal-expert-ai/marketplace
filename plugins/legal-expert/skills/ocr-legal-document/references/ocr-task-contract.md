# OCR task contract

## MCP tools

- `start_document_ocr(bundle_id, file_id, language?, idempotency_key)` starts one `document_ocr` task.
- `get_agent_task(task_id)` returns sanitized status and progress.
- `list_agent_task_outputs(task_id)` lists produced artifacts.
- `get_agent_task_output(task_id, output_id)` returns safe visible-output metadata.
- `read_agent_task_output_content(task_id, output_id, offset?, limit?)` reads visible UTF-8 output in pages of at most 20,000 characters.
- `read_agent_task_output_base64(task_id, output_id, byte_offset=0, byte_limit=196608)` reads any visible output as base64 chunks; `byte_limit` is at most 262,144. It returns `filename`, `mime_type`, `encoding`, `content_base64`, full-file `sha256`, `total_bytes`, and `next_byte_offset`. Follow byte offsets until null and verify the assembled bytes against `sha256`.
- `cancel_agent_task(task_id)` requests cancellation.

The source must be exactly one authorized PDF selected by `bundle_id` and `file_id` from a creator-owned ready bundle. File bytes, base64, upload handles, arbitrary remote URLs and local paths are forbidden in MCP JSON-RPC arguments.

The backend agent splits pages, OCRs and verifies them, combines a self-contained `final.html`, and may generate `final.docx`. The current MCP contract does not accept an output-format selector. If a page cannot be completed after retry policy, the task fails instead of returning an apparently complete partial document.

## Authorization and billing

Require `MCP_ACCESS`, the relevant OAuth scope, `AGENT_TASKS_INCLUDED`, available credits and tenant-scoped source/task access on every call. Starting a task is idempotent and must never double-charge on retry.

## Stable errors

Use `unauthorized`, `subscription_required`, `forbidden_scope`, `feature_required`, `credits_required`, `invalid_input`, `encrypted_document`, `unsupported_media_type`, `file_too_large`, `not_found`, `processing`, `rate_limited`, `upstream_unavailable`, `task_failed`, or `cancelled`.

Never return provider credentials, task JWTs, GCS paths, stack traces or raw stderr.
