import assert from "node:assert/strict";
import test from "node:test";
import { HttpsError } from "firebase-functions/v2/https";
import { DAILY_REQUEST_LIMIT, createDailyQuotaEnforcer } from "./dailyQuota.js";

function createFakeDatabase(initialQuota) {
  let quota = initialQuota;
  const reference = { path: "serverLimits/anthropicDaily" };

  return {
    doc(path) {
      assert.equal(path, reference.path);
      return reference;
    },
    async runTransaction(operation) {
      await operation({
        async get(receivedReference) {
          assert.equal(receivedReference, reference);
          return {
            exists: quota !== undefined,
            data: () => quota,
          };
        },
        set(receivedReference, nextQuota) {
          assert.equal(receivedReference, reference);
          quota = nextQuota;
        },
      });
    },
    getQuota() {
      return quota;
    },
  };
}

test("enforceDailyQuota increments the current day count", async () => {
  const database = createFakeDatabase({ day: "2026-09-01", requestCount: 4 });
  const enforceDailyQuota = createDailyQuotaEnforcer(
    database,
    () => new Date("2026-09-01T12:00:00Z"),
  );

  await enforceDailyQuota();

  assert.deepEqual(database.getQuota(), { day: "2026-09-01", requestCount: 5 });
});

test("enforceDailyQuota resets the count on a new UTC day", async () => {
  const database = createFakeDatabase({ day: "2026-08-31", requestCount: DAILY_REQUEST_LIMIT });
  const enforceDailyQuota = createDailyQuotaEnforcer(
    database,
    () => new Date("2026-09-01T00:00:00Z"),
  );

  await enforceDailyQuota();

  assert.deepEqual(database.getQuota(), { day: "2026-09-01", requestCount: 1 });
});

test("enforceDailyQuota rejects requests after the daily limit", async () => {
  const database = createFakeDatabase({
    day: "2026-09-01",
    requestCount: DAILY_REQUEST_LIMIT,
  });
  const enforceDailyQuota = createDailyQuotaEnforcer(
    database,
    () => new Date("2026-09-01T12:00:00Z"),
  );

  await assert.rejects(
    enforceDailyQuota(),
    (error) => error instanceof HttpsError && error.code === "resource-exhausted",
  );
  assert.equal(database.getQuota().requestCount, DAILY_REQUEST_LIMIT);
});
