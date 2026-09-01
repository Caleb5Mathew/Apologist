import assert from "node:assert/strict";
import test from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import {
  MAX_PROMPT_CHARACTERS,
  MODEL,
  createAnswerGenerator,
  extractResponseText,
  mapProviderError,
  validatePrompt,
} from "./anthropicProxy.js";

test("generateAnswer sends the validated request and returns joined text", async () => {
  let receivedParameters;
  const generateAnswer = createAnswerGenerator(async (parameters) => {
    receivedParameters = parameters;
    return {
      content: [
        { type: "text", text: "Clear " },
        { type: "text", text: "answer." },
      ],
    };
  });

  const result = await generateAnswer({ prompt: "  Why pray?  " });

  assert.deepEqual(result, { text: "Clear answer." });
  assert.equal(receivedParameters.model, MODEL);
  assert.equal(receivedParameters.max_tokens, 512);
  assert.match(receivedParameters.system, /Christian Protestant perspective/);
  assert.deepEqual(receivedParameters.messages, [{ role: "user", content: "Why pray?" }]);
});

test("validatePrompt rejects missing, blank, and oversized prompts", () => {
  for (const data of [
    {},
    { prompt: "   " },
    { prompt: "a".repeat(MAX_PROMPT_CHARACTERS + 1) },
  ]) {
    assert.throws(
      () => validatePrompt(data),
      (error) => error instanceof HttpsError && error.code === "invalid-argument",
    );
  }
});

test("extractResponseText rejects an empty provider response", () => {
  assert.throws(
    () => extractResponseText({ content: [{ type: "tool_use", id: "1" }] }),
    (error) => error instanceof HttpsError && error.code === "internal",
  );
});

test("mapProviderError maps rate limits without exposing provider details", () => {
  const error = mapProviderError({ status: 429, message: "sensitive provider response" });

  assert.equal(error.code, "resource-exhausted");
  assert.doesNotMatch(error.message, /sensitive provider response/);
});

test("mapProviderError maps network and server failures to unavailable", () => {
  for (const providerError of [
    { status: 503 },
    { name: "APIConnectionError" },
    { name: "APIConnectionTimeoutError" },
  ]) {
    const error = mapProviderError(providerError);
    assert.equal(error.code, "unavailable");
  }
});

test("mapProviderError sanitizes authentication failures", () => {
  const error = mapProviderError({ status: 401, message: "invalid secret value" });

  assert.equal(error.code, "internal");
  assert.doesNotMatch(error.message, /invalid secret value/);
});
