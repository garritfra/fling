import { describe, it, expect, beforeEach } from "vitest";
import { runMigrations, type Migration, type MigrationState } from "../../migrations/runner";

class InMemoryState implements MigrationState {
  applied = new Set<string>();
  async isApplied(id: string) { return this.applied.has(id); }
  async markApplied(id: string) { this.applied.add(id); }
}

describe("migrations runner", () => {
  let state: InMemoryState;
  beforeEach(() => { state = new InMemoryState(); });

  it("runs a pending migration once", async () => {
    let calls = 0;
    const m: Migration = { id: "001-test", up: async () => { calls++; } };
    await runMigrations([m], state);
    expect(calls).toBe(1);
    expect(await state.isApplied("001-test")).toBe(true);
  });

  it("skips an already-applied migration", async () => {
    let calls = 0;
    const m: Migration = { id: "001-test", up: async () => { calls++; } };
    await runMigrations([m], state);
    await runMigrations([m], state);
    expect(calls).toBe(1);
  });

  it("runs migrations in declared order and stops on failure", async () => {
    const order: string[] = [];
    const ms: Migration[] = [
      { id: "001", up: async () => { order.push("001"); } },
      { id: "002", up: async () => { throw new Error("boom"); } },
      { id: "003", up: async () => { order.push("003"); } },
    ];
    await expect(runMigrations(ms, state)).rejects.toThrow("boom");
    expect(order).toEqual(["001"]);
    expect(await state.isApplied("001")).toBe(true);
    expect(await state.isApplied("002")).toBe(false);
    expect(await state.isApplied("003")).toBe(false);
  });
});
