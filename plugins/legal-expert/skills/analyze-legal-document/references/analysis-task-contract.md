# Legal document analysis task contract

## MCP tools

- `start_legal_document_review(bundle_id, file_id, depth?, party_perspective?, language?, instructions?, idempotency_key)` starts one `document_legal_review` task.
- `get_agent_task(task_id)` returns sanitized status, progress, public progress key/message, timestamps and a safe failure code.
- `list_agent_task_outputs(task_id)` lists finished artifacts without storage credentials.
- `get_agent_task_output(task_id, output_id)` returns safe visible-output metadata.
- `read_agent_task_output_content(task_id, output_id, offset?, limit?)` reads visible UTF-8 report content in pages of at most 20,000 characters.
- `read_agent_task_output_base64(task_id, output_id, byte_offset=0, byte_limit=196608)` reads any visible output as base64 chunks; `byte_limit` is at most 262,144. It returns `filename`, `mime_type`, `encoding`, `content_base64`, full-file `sha256`, `total_bytes`, and `next_byte_offset`. Follow byte offsets until null and verify the assembled bytes against `sha256`.
- `cancel_agent_task(task_id)` requests cancellation of the exact task.

The source is a creator-owned ready bundle selected by `bundle_id` and exact `file_id`. Never put file bytes, base64, arbitrary URLs, local paths or caller-supplied user/organization IDs in tool arguments.

## Inputs and outputs

Supported backend inputs are PDF, DOCX, DOC, HTML and Markdown. The current agent reviews one primary document and produces:

- `final-report.html`: executive summary;
- `final-review.html`: interactive detailed review grouped by document section.

Depth is `quick`, `standard` or `deep`. Perspective is `prestator`, `beneficiar` or `balanced`. The service must persist these options with the task for auditability.

## Authorization and accounting

Require, on every call:

- OAuth audience/resource and the required agent/document scope;
- active local user and organization;
- `MCP_ACCESS` as the outer gate;
- `AGENT_TASKS_INCLUDED` and available agent-task credits;
- creator/folder/bundle authorization for the exact source and task.

Creation is idempotent. Replaying the same key and equivalent input returns the same task and must not consume credits twice.

## Stable states and errors

States: `queued`, `in_progress`, `completed`, `failed`, `cancelled`.

Stable errors include `unauthorized`, `subscription_required`, `forbidden_scope`, `feature_required`, `credits_required`, `invalid_input`, `not_found`, `conflict`, `processing`, `rate_limited`, `upstream_unavailable`, `task_failed`, and `cancelled`.

Do not return stack traces, agent prompts, raw stderr, GCS paths, signed URL history or task credentials.
