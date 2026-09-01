import Anthropic from "@anthropic-ai/sdk";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { onCall } from "firebase-functions/v2/https";
import { createAnswerGenerator, validatePrompt } from "./anthropicProxy.js";
import { createDailyQuotaEnforcer } from "./dailyQuota.js";

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");
const firebaseApp = getApps()[0] ?? initializeApp();
const enforceDailyQuota = createDailyQuotaEnforcer(getFirestore(firebaseApp));

export const generateApologistAnswer = onCall(
  {
    region: "us-central1",
    secrets: [anthropicApiKey],
    enforceAppCheck: true,
    timeoutSeconds: 50,
    memory: "256MiB",
    concurrency: 5,
    maxInstances: 2,
  },
  async (request) => {
    const client = new Anthropic({
      apiKey: anthropicApiKey.value(),
      timeout: 45_000,
      maxRetries: 0,
    });
    const generateAnswer = createAnswerGenerator((parameters) => client.messages.create(parameters));
    validatePrompt(request.data);
    await enforceDailyQuota();
    return generateAnswer(request.data);
  },
);
