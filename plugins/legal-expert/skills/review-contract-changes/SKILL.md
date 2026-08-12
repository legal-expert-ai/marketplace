---
name: review-contract-changes
description: Use Legal Expert to compare an original and modified contract, or inspect a single DOCX with Word Track Changes, and produce per-change Romanian-law recommendations. Use for contract redline analysis, version comparison, negotiation review, track-changes review, changed-clause risk assessment, or accept/partially accept/reject recommendations.
---

# Review Contract Changes

Run Legal Expert's contract-modifications agent through MCP. This is a substantive negotiation and legal-risk review, not merely a textual diff.

Read [references/contract-changes-task-contract.md](references/contract-changes-task-contract.md) before creating the task.

## Diagnose the connection

- **Unavailable:** If the Legal Expert server cannot connect or initialize, times out, fails DNS/TLS, or exposes no Legal Expert tool namespace, report that the service is unavailable and stop. Do not describe this as an account or subscription problem.
- **Unauthorized:** If the reachable server returns `unauthorized` or requests OAuth connection, ask the user to connect or reconnect their Legal Expert account. Retry only after they confirm that authentication completed.
- **Missing tool:** If the server is reachable and advertises tools but the exact required tool is absent, name that tool and report a deployment/capability mismatch. Do not substitute a similarly named tool or call this an outage.

## Select the comparison mode

- Two-file mode: choose exactly one original and one modified version.
- Track-changes mode: choose exactly one DOCX containing Word revisions/comments.

Resolve source roles explicitly. For files in a Legal Expert bundle, preserve `bundle_id`, both `file_id` values, versions and checksums. Do not infer original/modified order from upload order alone when filenames or metadata conflict.

Preview v1 accepts only files in the same creator-owned ready bundle. Inspect advertised tools first; if `start_contract_changes_review` is absent, stop and report the capability gap.

If multiple amendments or versions exist, show the proposed comparison pair and ask only when the choice changes the legal meaning. Do not fan out several paid comparisons without the user's authorization.

## Run the review

Call `start_contract_changes_review` once with `bundle_id`, `mode`, the exact mode-specific file IDs, output language, optional page cap, and a stable idempotency key. Poll `get_agent_task` with bounded backoff; reuse the task ID on retries.

The result should identify substantive changes, render inline diffs and classify recommendations such as accept, partially accept, reject, negotiate or review. Legal recommendations must retain the Romanian-law citations returned by the service.

Inspect final report metadata through `list_agent_task_outputs` and `get_agent_task_output`. Read visible UTF-8 report content with `read_agent_task_output_content`, following `next_offset`. Read visible binary artifacts with `read_agent_task_output_base64`, following `next_byte_offset`, and verify assembled bytes against the returned full-file SHA-256. Never expose base64 or probe storage. If the backend reports no substantive changes, say so without inventing negotiation issues.

## Present results

- Start with the highest-impact changes and executive counts.
- For each material change, distinguish the original wording, modified wording, commercial effect, legal basis and recommendation.
- Treat numerical terms, dates and commercial positions as negotiation items where appropriate rather than forcing a legal accept/reject answer.
- State whether the task analyzed two versions or native Word Track Changes.
- Do not apply, accept or reject changes in the source file unless the user separately requests an editing workflow.

## Access and privacy

Every call requires `MCP_ACCESS`, agent-task entitlement and credits, appropriate OAuth scope, and authorization for every selected source file and task. The service must re-check these on reads and cancellation, not only when the task starts.

Never expose provider keys, task tokens, storage paths, raw prompts/logs or another tenant's document existence.
