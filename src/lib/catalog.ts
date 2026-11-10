import type { Ingredient, WithId } from '../../schema';

/** Klein, getrimmt, Leerzeichen zusammengefasst – Grundlage für den Katalog-Abgleich. */
export function normalizeName(name: string): string {
  return name.normalize('NFC').toLowerCase().trim().replace(/\s+/g, ' ');
}

/** Grobe Singular/Plural-Angleichung ("Tomaten"/"Tomate", "Zwiebeln"/"Zwiebel"). */
function stem(normalized: string): string {
  const stripped = normalized.replace(/(en|n|e|s)$/, '');
  return stripped.length >= 3 ? stripped : normalized;
}

function namesOf(ingredient: Ingredient): string[] {
  return [ingredient.nameNormalized, ...ingredient.aliases];
}

/**
 * Sucht eine Zutat über `nameNormalized` und `aliases`.
 * Ohne exakten Treffer wird ein eindeutiger Treffer über Singular/Plural akzeptiert.
 */
export function findIngredient<T extends Ingredient>(name: string, catalog: WithId<T>[]): WithId<T> | undefined {
  const normalized = normalizeName(name);
  if (!normalized) return undefined;

  const exact = catalog.find((i) => namesOf(i).includes(normalized));
  if (exact) return exact;

  const target = stem(normalized);
  const fuzzy = catalog.filter((i) => namesOf(i).some((n) => stem(n) === target));
  return fuzzy.length === 1 ? fuzzy[0] : undefined;
}

/** Legt fest, wie eine neue Zutat aus einem Namen aussieht. */
export function newIngredient(name: string, category: string): Ingredient {
  const trimmed = name.trim().replace(/\s+/g, ' ');
  return {
    name: trimmed.charAt(0).toUpperCase() + trimmed.slice(1),
    nameNormalized: normalizeName(trimmed),
    aliases: [],
    category,
    pantryStaple: false,
  };
}

/** Zusammenführen: `source` wird zum Alias von `target`. Liefert die neuen Aliase von `target`. */
export function mergedAliases(target: Ingredient, source: Ingredient): string[] {
  const all = new Set([...target.aliases, source.nameNormalized, ...source.aliases]);
  all.delete(target.nameNormalized);
  return [...all];
}
