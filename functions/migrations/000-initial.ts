import type { Migration } from "./runner";

const migration: Migration = {
  id: "000-initial",
  up: async () => {
    // Intentional no-op. Establishes the migrations baseline so subsequent
    // migrations can rely on _migrations/000-initial existing.
  },
};

export default migration;
