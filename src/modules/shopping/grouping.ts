import type { Ingredient, ShoppingItem, Unit, WithId } from '../../../schema';
import { categoryIndex } from '../../lib/categories';
import { formatAmount, toBaseUnit, unitSortIndex } from '../../lib/units';

/**
 * Gespeichert wird ein Eintrag pro Herkunft – zusammengefasst wird nur hier, in der Anzeige.
 */
export interface ShoppingGroup {
  ingredientId: string;
  ingredient?: WithId<Ingredient>;
  name: string;
  category: string;
  items: WithId<ShoppingItem>[];
  /** Summe pro Dimension, z. B. [{200, 'g'}, {1, 'bund'}] */
  totals: { amount: number; unit: Unit }[];
}

/** Summen pro Dimension. Nicht umrechenbare Einheiten bleiben getrennt. */
export function sumAmounts(items: Pick<ShoppingItem, 'amount' | 'unit'>[]): { amount: number; unit: Unit }[] {
  const sums = new Map<Unit, number>();
  for (const item of items) {
    if (item.amount === undefined) continue;
    const base = toBaseUnit(item.amount, item.unit ?? 'stk');
    sums.set(base.unit, (sums.get(base.unit) ?? 0) + base.amount);
  }
  return [...sums.entries()]
    .map(([unit, amount]) => ({ amount, unit }))
    .sort((a, b) => unitSortIndex(a.unit) - unitSortIndex(b.unit));
}

/** "200 g + 1 Bund" – leer, wenn keiner der Einträge eine Menge hat. */
export function formatTotals(totals: { amount: number; unit: Unit }[]): string {
  return totals.map((t) => formatAmount(t.amount, t.unit)).join(' + ');
}

function buildGroups(items: WithId<ShoppingItem>[], catalog: Map<string, WithId<Ingredient>>): ShoppingGroup[] {
  const byIngredient = new Map<string, WithId<ShoppingItem>[]>();
  for (const item of items) {
    const list = byIngredient.get(item.ingredientId) ?? [];
    list.push(item);
    byIngredient.set(item.ingredientId, list);
  }
  const groups = [...byIngredient.entries()].map(([ingredientId, groupItems]): ShoppingGroup => {
    const ingredient = catalog.get(ingredientId);
    return {
      ingredientId,
      ingredient,
      name: ingredient?.name ?? '…',
      category: ingredient?.category ?? 'Sonstiges',
      items: groupItems.sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis()),
      totals: sumAmounts(groupItems),
    };
  });
  return groups.sort(
    (a, b) => categoryIndex(a.category) - categoryIndex(b.category) || a.name.localeCompare(b.name, 'de'),
  );
}

/**
 * Offene Einträge werden pro Zutat gruppiert und nach Kategorie sortiert.
 * Abgehakte Einträge bilden eigene Gruppen im Bereich „Erledigt“ – so entsteht für eine
 * bereits abgehakte Zutat, die erneut gebraucht wird, automatisch eine neue offene Gruppe.
 */
export function groupShoppingItems(
  items: WithId<ShoppingItem>[],
  ingredients: WithId<Ingredient>[],
): { open: ShoppingGroup[]; done: ShoppingGroup[] } {
  const catalog = new Map(ingredients.map((i) => [i.id, i]));
  return {
    open: buildGroups(items.filter((i) => !i.checkedAt), catalog),
    done: buildGroups(items.filter((i) => !!i.checkedAt), catalog),
  };
}
