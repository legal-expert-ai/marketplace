# Legal Expert legal-research MCP contract

All tools are read-only, idempotent, and gated by the authenticated Legal Expert account. Call only tools advertised by the connected server. Never bypass entitlement or tenant checks with internal services.

## Binding legislation

### `search_laws`

Searches Romanian or EU legislation without mixing Legalpedia commentary.

- `query`: required, 2–500 characters.
- `limit`: 1–20, default 10.
- `offset`: 0–200, default 0.
- `jurisdictions`: one or both of `RO`, `EU`; default `RO`.

Results include `source_type: binding_legislation`, stable act/article identifiers and metadata, total count, current offset, and `next_offset`. Abrogated search hits are filtered by the service, but still verify the selected act's effective metadata.

### `get_law`

`get_law(law_id)` returns authoritative act metadata, including publication/effective/abrogation fields and navigation links when available. `law_id` is a stable 1–64 character alphanumeric/hyphen identifier.

### `get_law_article`

`get_law_article(law_id, article)` returns one complete current article as Markdown, its heading/range/size metadata, truncation indicator, and previous/next article navigation. `article` is a 1–64 character article selector supplied by search/navigation, not an invented internal ID.

### `list_law_versions`

`list_law_versions(law_id)` returns current and historical consolidated versions plus navigation metadata. Select the version applicable on the user's requested date.

### `get_law_version`

`get_law_version(law_id, version_id, format="markdown", character_offset=0, character_limit=20000)` returns a paginated slice of a historical consolidated body.

- `format`: `markdown` or `html`.
- `character_offset`: 0–5,000,000.
- `character_limit`: 1,000–50,000.
- Follow `next_character_offset` until the required provision and qualifications are covered.

No separate historical-article, history, or link-retrieval tools exist in this contract.

## Legalpedia commentary

### `search_legalpedia`

`search_legalpedia(query, limit=10, category?)` searches curated explanatory content. Query length is 2–500 and limit is 1–20. Results have `source_type: legal_commentary`.

### `get_legalpedia_article`

`get_legalpedia_article(url_path)` retrieves the complete public article selected from a search result. `url_path` must be the returned Romanian path matching `/ro/...`; do not construct or guess one.

## Source discipline

Every material proposition should retain source type, law ID, act title/number, article selector or historical version ID, applicable date/version, and stable returned link. Label Legalpedia as commentary. Use the shortest necessary quotation and do not treat search snippets as complete provisions.

## Annotations and privacy

The tools advertise `readOnlyHint: true`, `destructiveHint: false`, `idempotentHint: true`, and `openWorldHint: true` because they retrieve external legal sources. Abstract confidential facts in search queries where possible. Never log tokens or imply consultation when a call fails.

Handle `unauthorized`, `subscription_required`, `invalid_input`, `not_found`, `rate_limited`, and upstream failures using only safe returned details.
