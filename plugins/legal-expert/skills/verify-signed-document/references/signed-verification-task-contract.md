# Signed document verification task contract

## MCP tools

- `start_signed_document_verification(bundle_id, approved_file_id, signed_file_id, language?, idempotency_key)` starts one `signed_document_verification` task.
- Shared lifecycle tools: `get_agent_task`, `list_agent_task_outputs`, `get_agent_task_output`, and `cancel_agent_task`.

The approved source must be one DOC/DOCX and the signed source must be one PDF in the same creator-owned ready bundle. The current MCP contract accepts their exact file IDs plus the bundle ID; upload handles, file bytes, base64, arbitrary URLs and local paths are forbidden.

`get_agent_task_output` returns safe visible-output metadata. Use `read_agent_task_output_content` for bounded UTF-8 report pages. `read_agent_task_output_base64(task_id, output_id, byte_offset=0, byte_limit=196608)` reads any visible output as base64 chunks; `byte_limit` is at most 262,144. It returns `filename`, `mime_type`, `encoding`, `content_base64`, full-file `sha256`, `total_bytes`, and `next_byte_offset`. Follow byte offsets until null and verify the assembled bytes against `sha256`.

The task produces `diff-report.html` for users, plus internal/hidden structured counts when available. The report verdict is `PASSED` or `FAILED` and differences are categorized as Critical, Important, Notice and Minor. Notice items represent OCR or formatting artifacts and do not trigger failure.

## Two independent statuses

- Task status: `queued`, `in_progress`, `completed`, `failed`, `cancelled`.
- Document verdict: `PASSED` or `FAILED`.

A produced `FAILED` verdict must be returned with task status `completed`. Use task status `failed` only when execution could not produce a reliable report.

## Authorization and accounting

Require `MCP_ACCESS`, the relevant OAuth scope, `AGENT_TASKS_INCLUDED`, available credits and tenant authorization for both sources and the task on every call. Creation is idempotent and cannot double-charge.

Use stable errors including `unauthorized`, `subscription_required`, `forbidden_scope`, `feature_required`, `credits_required`, `invalid_input`, `ambiguous_source_role`, `unsupported_media_type`, `encrypted_document`, `not_found`, `processing`, `rate_limited`, `upstream_unavailable`, `task_failed`, and `cancelled`.
