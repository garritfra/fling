import { Timestamp, doc, getDocs, query, where, writeBatch } from '@react-native-firebase/firestore';
import { ShoppingItem, type ShoppingSource, type Unit, type WithId } from '../../../schema';
import { db, fireAndForget } from '../../core/firebase';
import { householdCollection } from '../../core/paths';
import { useQuery } from '../../core/useQuery';

/**
 * Öffentliche Schnittstelle der Einkaufsliste. Andere Module schreiben nie direkt in
 * `shoppingItems`, sondern nutzen ausschließlich die Funktionen dieser Datei.
 *
 * Alle Schreibvorgänge sind Batches ohne await – sie funktionieren offline und werden
 * synchronisiert, sobald wieder Netz da ist. Keine Transaktionen (gehen offline nicht).
 */

const itemsCollection = (householdId: string) => householdCollection(householdId, 'shoppingItems');

export function useShoppingItems(householdId: string) {
  return useQuery(`shoppingItems:${householdId}`, () => itemsCollection(householdId), ShoppingItem);
}

export interface NewShoppingItem {
  ingredientId: string;
  /** In Basiseinheit (g, ml). */
  amount?: number;
  unit?: Unit;
}

/** Ein Eintrag pro Herkunft. Zusammengefasst wird nur in der Anzeige. */
export function addShoppingItems(
  householdId: string,
  items: NewShoppingItem[],
  source: ShoppingSource,
  createdBy: string,
): void {
  const batch = writeBatch(db);
  const createdAt = Timestamp.now();
  for (const item of items) {
    const entry: ShoppingItem = { ...item, source, createdAt, createdBy, checkedAt: null };
    batch.set(doc(itemsCollection(householdId)), entry);
  }
  fireAndForget(batch.commit());
}

/** Entfernt alle Einträge eines Plan-Eintrags. Manuelle Einträge bleiben unberührt. */
export async function removeShoppingItemsBySource(householdId: string, mealPlanEntryId: string): Promise<void> {
  // getDocs fällt offline auf den lokalen Cache zurück.
  const snapshot = await getDocs(
    query(itemsCollection(householdId), where('source.mealPlanEntryId', '==', mealPlanEntryId)),
  );
  const batch = writeBatch(db);
  snapshot.docs.forEach((d) => batch.delete(d.ref));
  fireAndForget(batch.commit());
}

/** Abhaken (oder zurücknehmen) aller übergebenen Einträge, z. B. einer ganzen Gruppe. */
export function setChecked(householdId: string, items: WithId<ShoppingItem>[], checked: boolean, personId: string): void {
  const batch = writeBatch(db);
  const now = Timestamp.now();
  for (const item of items) {
    batch.update(
      doc(itemsCollection(householdId), item.id),
      checked ? { checkedAt: now, checkedBy: personId } : { checkedAt: null },
    );
  }
  fireAndForget(batch.commit());
}

export function deleteShoppingItems(householdId: string, items: WithId<ShoppingItem>[]): void {
  const batch = writeBatch(db);
  items.forEach((item) => batch.delete(doc(itemsCollection(householdId), item.id)));
  fireAndForget(batch.commit());
}

/** Beim Zusammenführen von Katalog-Einträgen: Einträge auf die verbleibende Zutat umhängen. */
export function reassignIngredient(householdId: string, items: WithId<ShoppingItem>[], from: string, to: string): void {
  const batch = writeBatch(db);
  items
    .filter((item) => item.ingredientId === from)
    .forEach((item) => batch.update(doc(itemsCollection(householdId), item.id), { ingredientId: to }));
  fireAndForget(batch.commit());
}
