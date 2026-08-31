const { defineSecret } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const {
  createAnthropicClient,
  createClaudeAnswer,
  validateContext,
} = require("./claude");

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

function mapClaudeError(error) {
  if (error instanceof TypeError || error instanceof RangeError) {
    return new HttpsError("invalid-argument", "The question or conversation history is invalid.");
  }

  if (error?.status === 429) {
    return new HttpsError("resource-exhausted", "Claude is busy. Please try again shortly.");
  }

  if (error?.status >= 500) {
    return new HttpsError("unavailable", "Claude is temporarily unavailable.");
  }

  return new HttpsError("internal", "Claude could not answer this question.");
}

async function answerQuestion(data, apiKey, clientFactory = createAnthropicClient) {
  const context = validateContext(data?.context);
  const client = clientFactory(apiKey);
  const text = await createClaudeAnswer(client, context);
  return { text };
}

exports.answerApologistQuestion = onCall(
  {
    enforceAppCheck: true,
    memory: "256MiB",
    region: "us-central1",
    secrets: [anthropicApiKey],
    timeoutSeconds: 45,
  },
  async (request) => {
    try {
      return await answerQuestion(request.data, anthropicApiKey.value());
    } catch (error) {
      logger.error("Claude request failed", {
        requestId: error?._request_id,
        status: error?.status,
        type: error?.name,
      });
      throw mapClaudeError(error);
    }
  },
);

exports.answerQuestion = answerQuestion;
exports.mapClaudeError = mapClaudeError;
