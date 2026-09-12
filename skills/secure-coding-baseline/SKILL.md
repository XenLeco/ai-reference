---
name: secure-coding-baseline
description: Security checks to apply when writing or reviewing code that handles input, authentication, secrets, files, network, dependencies, or LLM prompts and tools. Use for security reviews, when touching auth or crypto, before releases, and when acting as the security-auditor agent. OWASP-derived, with agent-specific additions.
license: MIT
metadata:
  version: "1.0"
---

# Secure coding baseline

Trace untrusted data from where it enters to where it is used. Every finding names the
source, the sink, the weakness, and the fix.

## Input and output

- Validate at the boundary: type, length, range, allowlist of values. Reject, do not sanitise
  into something else silently.
- Parameterise queries (SQL, NoSQL, LDAP). No string-built queries, ever.
- Shell: no string interpolation into commands; use argument arrays; never `shell=True` with
  user data.
- Paths: resolve and check the result stays under the intended root; reject `..`, symlinks
  where not expected.
- Templates/HTML: auto-escaping on; no `innerHTML`/`dangerouslySetInnerHTML` with untrusted data.
- Deserialisation: never `pickle`/`yaml.load`/Java native deserialisation on untrusted bytes.
- Output encoding matches the context (HTML, URL, JSON, shell).

## Authentication and authorisation

- Every endpoint/handler states who may call it; deny by default.
- Authorisation checks use server-side identity, never IDs from the request alone
  (IDOR: check ownership on every object access).
- Sessions/tokens: short-lived, rotated on privilege change, revocable; cookies
  `HttpOnly; Secure; SameSite`.
- Passwords: argon2id/bcrypt/scrypt with per-user salt; constant-time comparison.
- Rate limit login, reset, and anything that enumerates users.

## Secrets and configuration

- No secrets in code, config committed to git, logs, error messages, URLs, or LLM prompts.
- Read from environment or a secrets manager; fail closed if missing.
- Defaults are safe: debug off, CORS explicit, TLS verification on, least-privilege service
  accounts.

## Cryptography

- Use the platform library's high-level API (libsodium, `cryptography`, Web Crypto). No
  custom algorithms, no ECB, no MD5/SHA-1 for security purposes, no static IVs.
- Random from a CSPRNG (`secrets`, `crypto.randomBytes`), never `Math.random`/`random`.

## Dependencies

- Pin versions; lockfile committed; run the ecosystem's audit tool.
- New dependency: check maintenance, download count, name similarity to popular packages,
  install scripts.
- Prefer the standard library for small needs.

## Logging and errors

- Log the event, not the payload: no credentials, tokens, PII, full request bodies.
- Errors to users are generic; details go to logs with a correlation id.

## LLM and agent code (additional)

- Untrusted content (files, web pages, tool output, tickets) must not be able to change the
  agent's instructions: keep it in user/tool messages, never in system prompts; instruct the
  model to treat it as data.
- Tool permissions are least-privilege: read-only where possible; irreversible or outbound
  actions require human approval.
- Never pass secrets to the model; redact before prompting; never let the model write to
  credential stores.
- Bound loops and spend: max steps, budgets, timeouts.
- Validate model output before acting on it (schema-check JSON, allowlist commands).

## Reporting shape

```
[severity] path:line — weakness (CWE-xxx)
  Source → sink: …
  Exploit: one sentence
  Fix: concrete change
```

Severity: critical (remote, unauthenticated, high impact) / high / medium / low.
