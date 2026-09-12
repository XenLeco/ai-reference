"""Call the gateway from Python with both official SDKs.

    pip install openai anthropic
    export LITELLM_API_KEY=sk-...          # a virtual key
    export LITELLM_BASE_URL=http://localhost:4000
    python python_openai_and_anthropic.py
"""

import os

from anthropic import Anthropic
from openai import OpenAI

BASE = os.environ.get("LITELLM_BASE_URL", "http://localhost:4000")
KEY = os.environ["LITELLM_API_KEY"]


def via_openai_format() -> None:
    """Chat Completions on /v1: works for every model the gateway serves."""
    client = OpenAI(base_url=f"{BASE}/v1", api_key=KEY)
    resp = client.chat.completions.create(
        model="coder-fast",  # a role alias; the gateway decides the vendor
        messages=[{"role": "user", "content": "Reply with the single word OK."}],
        max_tokens=16,
        extra_headers={"x-litellm-tags": "sdk-example"},
    )
    print("openai-format:", resp.choices[0].message.content)


def via_anthropic_format() -> None:
    """Anthropic Messages on the gateway root: the Anthropic SDK, unchanged except base_url."""
    client = Anthropic(base_url=BASE, api_key=KEY)
    with client.messages.stream(
        model="claude-opus-5",
        max_tokens=1024,
        thinking={"type": "adaptive"},
        messages=[{"role": "user", "content": "In one sentence, what is a gateway for?"}],
    ) as stream:
        message = stream.get_final_message()
    text = "".join(block.text for block in message.content if block.type == "text")
    print("anthropic-format:", text)


if __name__ == "__main__":
    via_openai_format()
    via_anthropic_format()
