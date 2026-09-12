# ADR-0001: A single gateway is the only path to model providers

Date: 2026-09-11 · Status: accepted

## Context

Several clients (OpenCode, Claude Code, Codex, Cursor, scripts, CI) need several vendors
(Anthropic, OpenAI, local Ollama/vLLM, hosted open models). Configuring each client for
each vendor multiplies credentials, model names and failure handling, and makes cost
invisible.

## Decision

All model traffic goes through one LiteLLM gateway. Clients receive a base URL and a
virtual key. Vendor credentials exist only in the gateway's environment. Model naming,
fallbacks, budgets and logging are gateway concerns.

## Alternatives considered

- **Direct vendor keys per client**: simplest to start, unmanageable at three tools and two
  vendors; no unified spend view; key rotation touches every machine.
- **Vendor-specific gateways** (Anthropic's Claude apps gateway, OpenAI-only proxies): good
  for one vendor, but this setup is multi-vendor by design.
- **Other multi-vendor gateways** (Portkey, Kong AI, Envoy AI Gateway, OpenRouter as a
  service): viable. LiteLLM won on three-format support on one port (Chat Completions,
  Responses, Anthropic Messages), open source, and single-container simplicity for the
  personal profile. Replacing it later only changes base URLs.

## Consequences

- One more service to run and keep updated; the gateway must forward new client features.
- Clients that cannot set a base URL are second-class (documented in 04).
- Enables the enterprise profile without changing the client layout.
