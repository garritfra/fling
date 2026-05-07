import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: false,
    environment: "node",
    setupFiles: ["./test/setup.ts"],
    include: ["test/**/*.test.ts"],
    testTimeout: 15_000,
    // All test files share the same Firestore + Auth emulator. Several
    // suites do collection-wide wipes in beforeEach (`users/`,
    // `idempotency_keys/`), which races against concurrent suites if
    // workers run in parallel. Force single-process execution so file
    // order is deterministic and beforeEach hooks can't trample each
    // other mid-test.
    pool: "forks",
    poolOptions: {
      forks: {
        singleFork: true,
      },
    },
  },
});
