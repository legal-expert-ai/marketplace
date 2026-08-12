---
name: ocr-legal-document
description: Convert a scanned legal PDF through Legal Expert's verified OCR workflow into navigable, self-contained HTML and optionally DOCX. Use for scanned contracts, image-only PDFs, poor text extraction, searchable legal-document conversion, page-preserving OCR, or requests to make a scanned legal document readable and reusable.
---

# OCR Legal Document

Use the authenticated Legal Expert OCR service. Do not substitute an unverified local text extraction while presenting it as the Legal Expert OCR result.

Read [references/ocr-task-contract.md](references/ocr-task-contract.md) before starting a task.

## Diagnose the connection

- **Unavailable:** If the Legal Expert server cannot connect or initialize, times out, fails DNS/TLS, or exposes no Legal Expert tool namespace, report that the service is unavailable and stop. Do not describe this as an account or subscription problem.
- **Unauthorized:** If the reachable server returns `unauthorized` or requests OAuth connection, ask the user to connect or reconnect their Legal Expert account. Retry only after they confirm that authentication completed.
- **Missing tool:** If the server is reachable and advertises tools but the exact required tool is absent, name that tool and report a deployment/capability mismatch. Do not substitute a similarly named tool or call this an outage.

## Prepare the source

1. Inspect advertised MCP tools and resolve exactly one PDF already present in a creator-owned ready Legal Expert document bundle. Preview v1 does not accept local paths, attachments, arbitrary URLs, or upload handles directly.
2. Preserve the surrounding bundle identity. OCR operates on the selected file; it must not split the file into a new library bundle or detach it from its contract family.
3. Identify encrypted, malformed, oversized or unsupported input before consuming credits where possible.
4. Explain that preview v1 does not expose an output-format selector. Report whichever visible artifacts the server produces.

## Run and monitor OCR

Call `start_document_ocr` once with `bundle_id`, `file_id`, `language`, and a stable idempotency key. If the tool is not advertised, stop and report the capability gap. The backend renders at high resolution, OCRs and verifies every page, combines the result, and fails rather than silently delivering a partial document.

Poll `get_agent_task` with bounded backoff. Do not create another OCR task because a large PDF is slow. If the user asks to stop, cancel only the exact task ID.

On completion, use `list_agent_task_outputs` and `get_agent_task_output` to inspect visible artifact metadata. Use `read_agent_task_output_content` for visible UTF-8 output and follow `next_offset`. Use `read_agent_task_output_base64` for visible binary output, follow `next_byte_offset`, assemble decoded chunks in byte order, and verify the result against the returned full-file SHA-256. Never expose base64 or probe storage.

## Quality and handoff

- Report page count, chosen outputs, unreadable/encrypted pages and any safe warnings returned by the service.
- Do not claim perfect transcription. For legally significant names, amounts, dates, account numbers, signatures or clause references, compare the output with the page image when the server exposes a page preview.
- Preserve page anchors so later analysis and comparison can cite the original document.
- Keep the OCR artifact linked to the original `bundle_id`, `file_id`, version and task ID.

## Access and privacy

- Every call requires a connected Legal Expert account, `MCP_ACCESS`, the agent-task product feature, credits and authorization for the exact source.
- A plugin skill file is not an entitlement boundary. The backend must reject every protected operation when the subscription is absent or cancelled.
- Never expose OCR provider keys, task tokens, raw page images outside the authorized workspace, storage paths or raw agent logs.
