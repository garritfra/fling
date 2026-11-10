import { deleteDoc, doc, setDoc, updateDoc } from '@react-native-firebase/firestore';
import { Ingredient, type WithId } from '../../schema';
import { mergedAliases, newIngredient, normalizeName } from '../lib/catalog';
import { fireAndForget } from '../core/firebase';
import { householdCollection } from '../core/paths';
import { useQuery } from '../core/useQuery';

/** Zutaten-Katalog des Haushalts. Wird von der Einkaufsliste und später von Rezepten genutzt. */
export function useIngredients(householdId: string) {
  return useQuery(`ingredients:${householdId}`, () => householdCollection(householdId, 'ingredients'), Ingredient);
}

/** Legt eine Zutat an und liefert sofort ihre ID (Schreibvorgang läuft offline-fähig im Hintergrund). */
export function createIngredient(householdId: string, name: string, category: string): string {
  const ref = doc(householdCollection(householdId, 'ingredients'));
  fireAndForget(setDoc(ref, newIngredient(name, category)));
  return ref.id;
}

export function updateIngredient(
  householdId: string,
  ingredientId: string,
  changes: Partial<Pick<Ingredient, 'name' | 'category'>>,
): void {
  const update: Partial<Ingredient> = { ...changes };
  if (changes.name !== undefined) update.nameNormalized = normalizeName(changes.name);
  fireAndForget(updateDoc(doc(householdCollection(householdId, 'ingredients'), ingredientId), update));
}

/**
 * Doppelte Einträge zusammenführen: `source` wird zum Alias von `target` und gelöscht.
 * Verweise anderer Module müssen vorher über deren eigene Funktionen umgehängt werden.
 */
export function mergeIngredientInto(householdId: string, target: WithId<Ingredient>, source: WithId<Ingredient>): void {
  const col = householdCollection(householdId, 'ingredients');
  fireAndForget(updateDoc(doc(col, target.id), { aliases: mergedAliases(target, source) }));
  fireAndForget(deleteDoc(doc(col, source.id)));
}
