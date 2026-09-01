import { HttpsError } from "firebase-functions/v2/https";

export const DAILY_REQUEST_LIMIT = 100;

export function createDailyQuotaEnforcer(database, now = () => new Date()) {
  return async function enforceDailyQuota() {
    const day = now().toISOString().slice(0, 10);
    const quotaReference = database.doc("serverLimits/anthropicDaily");

    await database.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(quotaReference);
      const storedQuota = snapshot.exists ? snapshot.data() : undefined;
      const requestCount = storedQuota?.day === day ? storedQuota.requestCount : 0;

      if (requestCount >= DAILY_REQUEST_LIMIT) {
        throw new HttpsError("resource-exhausted", "The daily answer limit has been reached.");
      }

      transaction.set(quotaReference, {
        day,
        requestCount: requestCount + 1,
      });
    });
  };
}
