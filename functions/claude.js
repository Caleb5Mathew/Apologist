const Anthropic = require("@anthropic-ai/sdk");

const MODEL = "claude-sonnet-5";
const MAX_CONTEXT_LENGTH = 12_000;
const SYSTEM_PROMPT = `Respond from a Christian Protestant perspective without explicitly stating or making it obvious that you are Protestant. Give a clear, compassionate answer that directly addresses the user's question. Prioritize relevant Bible verses, and cite Protestant theologians, compatible Catholic thinkers, or books when they genuinely help. Address likely misconceptions or concerns and keep the answer under 240 words. Do not begin with a recap, generic preamble, or summary of the question.

Tailor the response to the user's perspective. Help them understand the answer with clarity, compassion, and biblical truth. Never claim certainty where faithful Christians reasonably disagree. When the question involves immediate danger, abuse, self-harm, or a medical or legal emergency, encourage the user to contact appropriate local help in addition to offering pastoral support.`;

function validateContext(value) {
  if (typeof value !== "string") {
    throw new TypeError("context must be a string");
  }

  const context = value.trim();
  if (context.length === 0 || context.length > MAX_CONTEXT_LENGTH) {
    throw new RangeError("context length is invalid");
  }

  return context;
}

function buildMessageRequest(context) {
  return {
    model: MODEL,
    max_tokens: 900,
    system: SYSTEM_PROMPT,
    messages: [{ role: "user", content: validateContext(context) }],
  };
}

function extractText(message) {
  const text = message.content
    .filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("")
    .trim();

  if (!text) {
    throw new Error("Claude returned no text");
  }

  return text;
}

async function createClaudeAnswer(client, context) {
  const message = await client.messages.create(buildMessageRequest(context));
  return extractText(message);
}

function createAnthropicClient(apiKey) {
  return new Anthropic({ apiKey, maxRetries: 0, timeout: 35_000 });
}

module.exports = {
  MODEL,
  SYSTEM_PROMPT,
  buildMessageRequest,
  createAnthropicClient,
  createClaudeAnswer,
  extractText,
  validateContext,
};
