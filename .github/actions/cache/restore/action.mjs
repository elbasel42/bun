import { setOutput } from "@actions/core";
import { restoreCache } from "../action.mjs";

async function main() {
  const result = await restoreCache();
  console.log("RESULT:", result);
  if (!result) {
    process.exit(1);
  }
  const { cacheHit, cacheKey } = result;
  console.log("Cache key:", cacheKey, cacheHit ? "(hit)" : "(miss)");
  setOutput("cache-hit", cacheHit);
  setOutput("cache-matched-key", cacheKey);
  if (cacheHit) {
    setOutput("cache-primary-key", cacheKey);
  }
}

main().catch(error => {
  console.error("Failed to restore cache:", error);
  process.exit(1);
});
