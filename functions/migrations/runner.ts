import { readdirSync } from "node:fs";
import { resolve, join } from "node:path";

export interface Migration {
  id: string;
  up: () => Promise<void>;
  down?: () => Promise<void>;
}

export interface MigrationState {
  isApplied(id: string): Promise<boolean>;
  markApplied(id: string): Promise<void>;
}

export async function runMigrations(
  migrations: Migration[],
  state: MigrationState,
  log: (msg: string) => void = console.log
): Promise<void> {
  for (const m of migrations) {
    if (await state.isApplied(m.id)) {
      log(`[migrate] skip ${m.id} (already applied)`);
      continue;
    }
    log(`[migrate] apply ${m.id}`);
    await m.up();
    await state.markApplied(m.id);
    log(`[migrate] done  ${m.id}`);
  }
}

/** Firestore-backed state used at runtime (lazy-loaded so tests don't need Admin SDK). */
export async function firestoreState(): Promise<MigrationState> {
  const admin = await import("firebase-admin");
  if (admin.apps.length === 0) admin.initializeApp();
  const db = admin.firestore();
  return {
    async isApplied(id) {
      const snap = await db.collection("_migrations").doc(id).get();
      return snap.exists;
    },
    async markApplied(id) {
      await db.collection("_migrations").doc(id).set({
        applied_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    },
  };
}

/** Discover and load all migration modules in this directory (NNN-*.ts). */
export async function loadMigrations(dir = __dirname): Promise<Migration[]> {
  const files = readdirSync(dir)
    .filter((f) => /^\d{3}-.*\.ts$/.test(f) && f !== "runner.ts")
    .sort();
  const mods = await Promise.all(
    files.map((f) => import(resolve(join(dir, f))) as Promise<{ default: Migration }>)
  );
  return mods.map((m) => m.default);
}

// CLI entrypoint: `tsx migrations/runner.ts`
if (require.main === module) {
  (async () => {
    const migrations = await loadMigrations();
    const state = await firestoreState();
    await runMigrations(migrations, state);
  })().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
