# clients/gemini-cli/ — Gemini CLI

Gemini CLI speaks the Gemini API and does not accept an OpenAI-compatible base URL, so it is
the one client here that talks to a vendor directly. Use it for Gemini models; keep the
shared context working:

- `GEMINI.md` at the repo root imports `AGENTS.md` (`templates/project/GEMINI.md`).
- MCP servers in `~/.gemini/settings.json`:

```json
{
  "mcpServers": {
    "context7": { "httpUrl": "https://mcp.context7.com/mcp" }
  }
}
```

Routing through the gateway: LiteLLM offers a Gemini-format pass-through and Gemini CLI reads
`GOOGLE_GEMINI_BASE_URL`; the combination works on some versions and not others. Verify
against the current Gemini CLI documentation before relying on it, and prefer a dedicated
Gemini API key with a spend cap otherwise.

Enterprise: Gemini CLI is vendor-direct. Allow it only for repos in the Public/Internal
classes and only with a key issued from the org's Google Cloud project (docs/08 §5).
