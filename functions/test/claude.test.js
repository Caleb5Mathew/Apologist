const assert = require("node:assert/strict");
const test = require("node:test");
const {
  MODEL,
  SYSTEM_PROMPT,
  buildMessageRequest,
  createAnthropicClient,
  createClaudeAnswer,
  extractText,
  validateContext,
} = require("../claude");

test("validateContext trims a valid question", () => {
  assert.equal(validateContext("  Why does God allow suffering?  "), "Why does God allow suffering?");
});

test("validateContext rejects empty and oversized input", () => {
  assert.throws(() => validateContext("   "), RangeError);
  assert.throws(() => validateContext("x".repeat(12_001)), RangeError);
  assert.throws(() => validateContext(null), TypeError);
});

test("buildMessageRequest uses current Sonnet model and apologetics prompt", () => {
  const request = buildMessageRequest("What is grace?");

  assert.equal(request.model, MODEL);
  assert.equal(MODEL, "claude-sonnet-5");
  assert.equal(request.system, SYSTEM_PROMPT);
  assert.match(request.system, /Christian Protestant perspective/);
  assert.deepEqual(request.messages, [{ role: "user", content: "What is grace?" }]);
});

test("extractText joins text blocks and ignores non-text blocks", () => {
  const result = extractText({
    content: [
      { type: "text", text: "First " },
      { type: "tool_use", id: "ignored" },
      { type: "text", text: "second" },
    ],
  });

  assert.equal(result, "First second");
});

test("extractText rejects an empty Claude response", () => {
  assert.throws(() => extractText({ content: [] }), /no text/);
});

test("createClaudeAnswer sends the request and returns text", async () => {
  let receivedRequest;
  const client = {
    messages: {
      create: async (request) => {
        receivedRequest = request;
        return { content: [{ type: "text", text: "By grace through faith." }] };
      },
    },
  };

  const answer = await createClaudeAnswer(client, "How are we saved?");

  assert.equal(answer, "By grace through faith.");
  assert.equal(receivedRequest.model, "claude-sonnet-5");
});

test("createAnthropicClient configures the official SDK", () => {
  const client = createAnthropicClient("test-key");

  assert.ok(client.messages);
});
