---
name: verify-signed-document
description: Verify with Legal Expert that a signed PDF preserves the legal content of an approved DOC or DOCX draft, producing a PASSED/FAILED report with categorized differences and OCR notices. Use for signature-copy verification, approved-draft versus signed-PDF checks, execution-version integrity, post-signing document comparison, or detecting changes introduced between approval and signature.
---

# Verify Signed Document

Use Legal Expert's signed-document verification workflow. This task answers a narrow integrity question: whether the signed PDF carries the same meaningful legal content as the approved editable draft.

Read [references/signed-verification-task-contract.md](references/signed-verification-task-contract.md) before starting.

## Diagnose the connection

- **Unavailable:** If the Legal Expert server cannot connect or initialize, times out, fails DNS/TLS, or exposes no Legal Expert tool namespace, report that the service is unavailable and stop. Do not describe this as an account or subscription problem.
- **Unauthorized:** If the reachable server returns `unauthorized` or requests OAuth connection, ask the user to connect or reconnect their Legal Expert account. Retry only after they confirm that authentication completed.
- **Missing tool:** If the server is reachable and advertises tools but the exact required tool is absent, name that tool and report a deployment/capability mismatch. Do not substitute a similarly named tool or call this an outage.

## Resolve the pair

Select exactly:

- one approved `.doc` or `.docx` source; and
- one signed `.pdf` source.

The current MCP contract accepts only authorized files from the same creator-owned ready Legal Expert document bundle. Preserve their bundle/file IDs, versions and checksums. Never guess which draft was approved when several versions exist; ask for the exact pair if that choice affects the verdict. Inspect advertised tools first and stop with a capability-gap explanation if the verification tool is absent.

## Run and monitor

Call `start_signed_document_verification` once with `bundle_id`, `approved_file_id`, `signed_file_id`, language, and a stable idempotency key. Poll `get_agent_task` with bounded backoff and do not duplicate a slow task.

The backend converts the approved file, OCRs the signed PDF, compares their legal content and produces a categorized report. Inspect visible artifacts through `list_agent_task_outputs` and `get_agent_task_output`, then read visible UTF-8 report pages with `read_agent_task_output_content`. Read visible binary artifacts with `read_agent_task_output_base64`, follow `next_byte_offset`, and verify assembled bytes against the returned full-file SHA-256. Never expose base64 or probe storage.

## Interpret the outcome correctly

- `PASSED` means no meaningful legal-content changes were detected within the workflow's limits.
- `FAILED` means critical or important differences were detected and must be reviewed.
- OCR/layout notices alone do not trigger `FAILED`.
- A task with a `FAILED` document verdict is still technically `completed` when the report was produced. Do not confuse the report verdict with task execution status.
- `task_failed` means the workflow could not produce a reliable report, for example because conversion or OCR failed.

Summarize critical and important differences first, then notices and minor changes. Encourage human review of every failed verdict and any ambiguity involving signatures, handwritten additions, dates, amounts, party names or missing pages.

## Access and privacy

Require `MCP_ACCESS`, agent-task entitlement and credits, appropriate OAuth scope, and authorization for both source objects and the task on every call. Never expose task tokens, provider credentials, storage paths, raw logs or cross-tenant existence.
