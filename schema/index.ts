/**
 * Datenmodell der Haushalts-App – einzige Quelle der Wahrheit.
 *
 * Alle Dokumente liegen unter `households/{householdId}/` (Ausnahme: `invites/{code}`).
 * Firestore-Timestamps werden strukturell geprüft, damit das Schema
 * unabhängig vom Firebase-SDK bleibt (App, Tests, später n8n).
 */
import { z } from 'zod';

/** Alles, was wie ein Firestore-Timestamp aussieht. */
export interface TimestampLike {
  toMillis(): number;
}
export const timestamp = z.custom<TimestampLike>(
  (v) => typeof v === 'object' && v !== null && typeof (v as TimestampLike).toMillis === 'function',
  { message: 'Timestamp erwartet' },
);

// ---------------------------------------------------------------------------
// Einheiten
// ---------------------------------------------------------------------------

export const units = ['g', 'kg', 'ml', 'l', 'stk', 'bund', 'dose', 'packung', 'el', 'tl', 'prise'] as const;
export const Unit = z.enum(units);
export type Unit = z.infer<typeof Unit>;

// ---------------------------------------------------------------------------
// Kern: Haushalt, Personen, Einladungen
// ---------------------------------------------------------------------------

export const Household = z.object({
  name: z.string(),
  /** Zugriff, Grundlage der Security Rules. */
  memberUids: z.array(z.string()),
  /** z. B. ['shopping'] */
  activeModules: z.array(z.string()),
  /** Einladungscode, mit dem zuletzt jemand beigetreten ist (von den Rules beim Beitritt verlangt). */
  inviteCode: z.string().optional(),
  /** Soft Delete, wenn das letzte Mitglied verlässt. */
  deletedAt: timestamp.optional(),
  createdAt: timestamp,
});
export type Household = z.infer<typeof Household>;

export const Person = z.object({
  displayName: z.string(),
  /** Verknüpfter Account; fehlt bei Gästen ohne App. */
  uid: z.string().optional(),
});
export type Person = z.infer<typeof Person>;

export const Invite = z.object({
  householdId: z.string(),
  /** uid */
  createdBy: z.string(),
  expiresAt: timestamp,
  usedAt: timestamp.optional(),
});
export type Invite = z.infer<typeof Invite>;

// ---------------------------------------------------------------------------
// Zutaten-Katalog (geteilt von Einkaufsliste und später Rezepten)
// ---------------------------------------------------------------------------

export const Ingredient = z.object({
  name: z.string(),
  /** klein, getrimmt, für Abgleich */
  nameNormalized: z.string(),
  /** normalisiert */
  aliases: z.array(z.string()),
  /** z. B. 'Obst & Gemüse', 'Kühlregal', 'Drogerie' */
  category: z.string(),
  defaultUnit: Unit.optional(),
  /** Grundvorrat: wird nie automatisch auf die Liste gesetzt. */
  pantryStaple: z.boolean(),
});
export type Ingredient = z.infer<typeof Ingredient>;

// ---------------------------------------------------------------------------
// Modul: Einkaufsliste
// ---------------------------------------------------------------------------

export const ShoppingSource = z.discriminatedUnion('type', [
  z.object({ type: z.literal('manual') }),
  z.object({ type: z.literal('mealPlan'), mealPlanEntryId: z.string(), recipeId: z.string() }),
]);
export type ShoppingSource = z.infer<typeof ShoppingSource>;

export const ShoppingItem = z.object({
  ingredientId: z.string(),
  /** In Basiseinheit (g, ml); optional ("Brot" ohne Menge ist gültig). */
  amount: z.number().positive().optional(),
  unit: Unit.optional(),
  source: ShoppingSource,
  checkedAt: timestamp.nullable().optional(),
  /** personId */
  checkedBy: z.string().optional(),
  createdAt: timestamp,
  /** personId */
  createdBy: z.string(),
});
export type ShoppingItem = z.infer<typeof ShoppingItem>;

/** Dokument plus seine Firestore-ID. */
export type WithId<T> = T & { id: string };
