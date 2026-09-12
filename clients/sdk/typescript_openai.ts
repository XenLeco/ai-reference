// Call the gateway from TypeScript with the OpenAI SDK, streaming.
//   npm i openai
//   LITELLM_API_KEY=sk-... LITELLM_BASE_URL=http://localhost:4000 npx tsx typescript_openai.ts
import OpenAI from "openai";

const base = process.env.LITELLM_BASE_URL ?? "http://localhost:4000";
const client = new OpenAI({
  baseURL: `${base}/v1`,
  apiKey: process.env.LITELLM_API_KEY,
  defaultHeaders: { "x-litellm-tags": "sdk-example" },
  timeout: 600_000, // ms; frontier models on hard prompts take minutes
});

async function main() {
  const stream = await client.chat.completions.create({
    model: "coder-fast", // role alias resolved by the gateway
    messages: [{ role: "user", content: "List three risks of running agents without a gateway." }],
    stream: true,
  });
  for await (const chunk of stream) {
    process.stdout.write(chunk.choices[0]?.delta?.content ?? "");
  }
  process.stdout.write("\n");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
