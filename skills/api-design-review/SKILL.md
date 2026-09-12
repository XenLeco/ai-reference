---
name: api-design-review
description: Review or design HTTP/JSON, gRPC or library APIs for consistency, evolvability, error handling and security. Use when adding or changing endpoints, public functions, event schemas or SDK surfaces, when asked "is this API well designed", or before publishing a contract.
license: MIT
metadata:
  version: "1.0"
---

# API design review

The question is not "does it work" but "can it change later without breaking callers".

## Contract

- Resource naming: plural nouns, consistent casing, no verbs in paths (`POST /orders`,
  not `/createOrder`); actions that are not CRUD get a sub-resource (`/orders/{id}/cancel`).
- Idempotency: `PUT`/`DELETE` idempotent by definition; `POST` that creates accepts an
  `Idempotency-Key` when clients may retry.
- Versioning: a strategy exists (path `/v1`, header, or additive-only with deprecation
  dates). Additive changes never bump; removals and type changes do.
- Fields: `snake_case` or `camelCase`, one of them; timestamps RFC 3339 UTC; money as
  integer minor units or decimal strings, never floats; ids opaque strings.
- Pagination: cursor-based with `next_cursor`; page size capped; total counts optional
  and explicitly approximate if expensive.
- Filtering/sorting: documented allowlist of fields.
- Partial responses and expansion (`fields=`, `expand=`) only when measured need exists.

## Errors

- One error shape everywhere: `{ "error": { "code": "order_not_found", "message": "...",
  "details": {...}, "request_id": "..." } }`. Codes are stable strings; messages may change.
- HTTP status matches semantics: 400 malformed, 401 unauthenticated, 403 unauthorised,
  404 missing (or 403 when existence is sensitive), 409 conflict, 422 validation, 429 with
  `Retry-After`, 5xx only for server faults.
- Validation errors list every failing field, not just the first.

## Security

- Authentication on every endpoint by default; authorisation checks object ownership.
- No sensitive data in URLs (query strings are logged).
- Rate limits and body size limits; timeouts on upstream calls.
- CORS explicit; no wildcard with credentials.

## Evolvability

- Clients must ignore unknown fields; document it. Never reuse a field name with a new
  meaning.
- Enums: clients treat unknown values as "other".
- Deprecation: header or field flag plus a removal date; telemetry on deprecated use.
- Events/webhooks: versioned type names, signed payloads, replay protection, documented
  delivery semantics (at-least-once).

## Library / SDK surfaces

- Small public surface; everything else private. Prefer keyword arguments and options
  objects over positional lists that will grow.
- Errors are typed; no string matching required.
- Semver honoured; a changelog exists (`release-notes` skill).

## Output shape

```
[blocker|should-fix|nit] <endpoint or symbol> — issue → proposal
Compatibility: <additive | breaking (needs version bump)>
```
