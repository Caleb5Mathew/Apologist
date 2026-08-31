const assert = require("node:assert/strict");
const test = require("node:test");
const { HttpsError } = require("firebase-functions/v2/https");
const { answerQuestion, mapClaudeError } = require("../index");

test("answerQuestion validates input and uses the configured client", async () => {
  let receivedKey;
  const result = await answerQuestion(
    { context: "What is grace?" },
    "server-secret",
    (apiKey) => {
      receivedKey = apiKey;
      return {
        messages: {
          create: async () => ({ content: [{ type: "text", text: "Grace is God's gift." }] }),
        },
      };
    },
  );

  assert.equal(receivedKey, "server-secret");
  assert.deepEqual(result, { text: "Grace is God's gift." });
});

test("mapClaudeError maps invalid input", () => {
  const error = mapClaudeError(new RangeError("bad input"));

  assert.ok(error instanceof HttpsError);
  assert.equal(error.code, "invalid-argument");
});

test("mapClaudeError maps rate limits", () => {
  const error = mapClaudeError({ status: 429 });

  assert.equal(error.code, "resource-exhausted");
});

test("mapClaudeError maps upstream outages", () => {
  const error = mapClaudeError({ status: 503 });

  assert.equal(error.code, "unavailable");
});

test("mapClaudeError hides unexpected failures", () => {
  const error = mapClaudeError(new Error("secret detail"));

  assert.equal(error.code, "internal");
  assert.equal(error.message, "Claude could not answer this question.");
});
