# Contract changes review task contract

## MCP tools

- `start_contract_changes_review(bundle_id, mode, original_file_id?, modified_file_id?, tracked_file_id?, language?, max_document_pages?, idempotency_key)` starts one `document_modifications_review` task.
- Shared lifecycle tools: `get_agent_task`, `list_agent_task_outputs`, `get_agent_task_output`, and `cancel_agent_task`.

The mode-specific file selection is one of:

- `{mode: "versions", original_file_id, modified_file_id}`;
- `{mode: "track_changes", tracked_file_id}`.

All selected file IDs belong to the same creator-owned ready `bundle_id`. Never accept upload handles, local paths, arbitrary URLs, bytes or base64 in preview v1.

`get_agent_task_output` returns safe visible-output metadata. Use `read_agent_task_output_content` for bounded UTF-8 report pages. `read_agent_task_output_base64(task_id, output_id, byte_offset=0, byte_limit=196608)` reads any visible output as base64 chunks; `byte_limit` is at most 262,144. It returns `filename`, `mime_type`, `encoding`, `content_base64`, full-file `sha256`, `total_bytes`, and `next_byte_offset`. Follow byte offsets until null and verify the assembled bytes against `sha256`.

The backend agent accepts one or two attachments according to mode and produces `changes-report.html`, with inline diffs, executive counts and per-change Romanian-law recommendations. PDF inputs may require OCR. A page cap must be visible in the result because trimming can limit completeness.

## Authorization and accounting

Require `MCP_ACCESS`, the relevant OAuth scope, `AGENT_TASKS_INCLUDED`, available credits, and authorization to every source and task on each call. Task creation is idempotent and retries must not double-charge.

## Stable errors

Include `unauthorized`, `subscription_required`, `forbidden_scope`, `feature_required`, `credits_required`, `invalid_input`, `ambiguous_source_role`, `unsupported_media_type`, `encrypted_document`, `not_found`, `processing`, `rate_limited`, `upstream_unavailable`, `task_failed`, and `cancelled`.
