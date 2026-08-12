---
name: research-romanian-law
description: Research Romanian law with the Legal Expert MCP tools by searching LawDB legislation, retrieving applicable legal text, and combining primary sources with Legal Expert wiki commentary. Use for Romanian legal questions, applicable-law research, article or act lookup, legislation effective on a date, amendment checks, source-backed legal summaries, and comparisons between legislation and doctrinal explanations. Trigger for requests in Romanian or English from lawyers, legal teams, compliance professionals, and Legal Expert subscribers.
---

# Research Romanian Law

Use Legal Expert as a research system, not as a substitute for professional judgment. Work only through the authenticated MCP tools; never attempt direct database access or bypass subscription checks.

## Diagnose the connection

- **Unavailable:** If the Legal Expert server cannot connect or initialize, times out, fails DNS/TLS, or exposes no Legal Expert tool namespace, report that the service is unavailable and stop. Do not describe this as an account or subscription problem.
- **Unauthorized:** If the reachable server returns `unauthorized` or requests OAuth connection, ask the user to connect or reconnect their Legal Expert account. Retry only after they confirm that authentication completed.
- **Missing tool:** If the server is reachable and advertises tools but the exact required tool is absent, name that tool and report a deployment/capability mismatch. Do not substitute a similarly named tool or call this an outage.

## Research workflow

1. Identify the legal issue, Romanian jurisdiction, relevant facts, and the date for which the law must be established. Ask a concise question only when an ambiguity could materially change the result.
2. Search LawDB for primary legislation. Use specific legal concepts, synonyms, act numbers, and `RO`/`EU` jurisdiction filters. Follow `next_offset` when the initial page is incomplete.
3. Retrieve the act metadata and exact current article before relying on wording. Check effective dates, repeal status, amendments, and transitional provisions. For historical questions, call `list_law_versions`, select the applicable `version_id`, and page through `get_law_version` using `next_character_offset`.
4. Search the Legal Expert wiki for explanations, related concepts, and practical context. Treat wiki material as secondary commentary, never as the source of a legal rule.
5. Cross-check every material proposition against the retrieved primary text. If sources conflict, explain the conflict and prefer the legislation applicable on the requested date.
6. Answer in the user's language. Distinguish clearly between law, Legal Expert commentary, and the analysis inferred from them.

## Tool use

Inspect the connected server's advertised tools before research. If `search_laws` is absent, stop and report a deployment or capability gap; do not substitute direct database or internal backend access.

- Use `search_laws` to discover relevant acts and provisions.
- Use `get_law` for act metadata and `get_law_article(law_id, article)` for exact current article text before quoting or analyzing wording.
- If an article response is marked truncated, state the retrieval limitation and do not infer omitted wording.
- Use `search_legalpedia` as a separate search for Legalpedia commentary. Do not merge its results with LawDB legislation or present it as primary law.
- Use `get_legalpedia_article(url_path)` to retrieve the complete public commentary selected from search results.
- Use `list_law_versions` and paginated `get_law_version` for historical consolidated text. Do not invent article/history/link tools that the server does not advertise.
- If the connected server exposes fewer tools, use only the available tools and state any resulting verification limit.
- Keep calls narrow. Request only the fields and passages required for the user's question.

Read [references/tool-contracts.md](references/tool-contracts.md) when implementing, debugging, or evaluating the Legal Expert MCP server, or when exact inputs, outputs, authorization behavior, and errors are needed.

## Subscriber access

- Treat the authenticated Legal Expert identity and server-side `MCP_ACCESS` entitlement as the sole source of plugin access.
- On `unauthorized`, ask the user to connect or reconnect their Legal Expert account.
- On `subscription_required`, explain that the account does not currently include Legal Expert MCP access and stop calling gated tools.
- Never reveal access tokens, internal diagnostics, hidden account data, or infrastructure identifiers.
- Never imply that restricted LawDB or wiki content was consulted when access was denied.

## Source discipline

- Never invent an act, article number, quotation, effective date, amendment, or source URL.
- Cite the act title and number, article or section, applicable version date, and stable Legal Expert source identifier or URL when returned.
- Quote only the minimum text needed. Paraphrase the remainder and preserve legally significant qualifications.
- Label commentary as commentary. Do not attribute commentary language to legislation.
- State when the available sources do not establish a reliable answer.

## Response shape

Use the smallest structure that remains auditable:

1. Direct answer or working conclusion.
2. Primary legal basis with precise citations.
3. Relevant Legal Expert commentary.
4. Analysis connecting the sources to the user's facts.
5. Material uncertainties, date limitations, or missing facts.

Add a brief reminder that the result is legal research support, not individualized legal advice, when the answer could materially affect rights, deadlines, litigation, compliance, or transactions.

## Privacy

Minimize personal, client, and case data in tool inputs. Do not send names, identifiers, or confidential narrative when an abstracted fact pattern is sufficient. If sensitive detail is necessary, tell the user what is needed and why before including it.
