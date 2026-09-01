import { HttpsError } from "firebase-functions/v2/https";

export const MODEL = "claude-sonnet-5";
export const MAX_PROMPT_CHARACTERS = 16_000;

const SYSTEM_PROMPT = `
Respond from a Christian Protestant perspective without announcing the denomination. Give a clear,
compassionate answer that directly addresses the question. Prioritize relevant Bible verses, and cite
Protestant theologians, compatible Catholic thinkers, or books when they genuinely help. Address likely
misconceptions and keep the answer under 240 words. Do not begin with a recap or generic preamble.
`.trim();

export function validatePrompt(data) {
  if (typeof data?.prompt !== "string") {
    throw new HttpsError("invalid-argument", "A prompt is required.");
  }

  const prompt = data.prompt.trim();
  if (prompt.length === 0 || prompt.length > MAX_PROMPT_CHARACTERS) {
    throw new HttpsError("invalid-argument", "The prompt length is invalid.");
  }

  return prompt;
}

export function extractResponseText(message) {
  const text = message?.content
    ?.filter((block) => block.type === "text")
    .map((block) => block.text)
    .join("")
    .trim();

  if (!text) {
    throw new HttpsError("internal", "The answer could not be generated.");
  }

  return text;
}

export function mapProviderError(error) {
  if (error instanceof HttpsError) {
    return error;
  }

  if (error?.status === 429) {
    return new HttpsError("resource-exhausted", "The service is busy. Try again shortly.");
  }

  if (error?.status >= 500 || error?.name === "APIConnectionError" || error?.name === "APIConnectionTimeoutError") {
    return new HttpsError("unavailable", "The answer service is temporarily unavailable.");
  }

  return new HttpsError("internal", "The answer could not be generated.");
}

export function createAnswerGenerator(createMessage) {
  return async function generateAnswer(data) {
    const prompt = validatePrompt(data);

    try {
      const message = await createMessage({
        model: MODEL,
        max_tokens: 512,
        system: SYSTEM_PROMPT,
        messages: [{ role: "user", content: prompt }],
      });

      return { text: extractResponseText(message) };
    } catch (error) {
      throw mapProviderError(error);
    }
  };
}
