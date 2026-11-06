import { describe, expect, it } from 'vitest';
import type { Ingredient, ShoppingItem, WithId } from '../../schema';
import { newIngredient } from '../../src/lib/catalog';
import { formatTotals, groupShoppingItems } from '../../src/modules/shopping/grouping';

const ts = (ms: number) => ({ toMillis: () => ms });

const item = (id: string, ingredientId: string, extra: Partial<ShoppingItem> = {}): WithId<ShoppingItem> => ({
  id,
  ingredientId,
  source: { type: 'manual' },
  createdAt: ts(Number(id.replace(/\D/g, '')) || 0),
  createdBy: 'p1',
  ...extra,
});

const catalog: WithId<Ingredient>[] = [
  { id: 'parsley', ...newIngredient('Petersilie', 'Obst & Gemüse') },
  { id: 'milk', ...newIngredient('Milch', 'Kühlregal') },
  { id: 'apple', ...newIngredient('Apfel', 'Obst & Gemüse') },
  { id: 'soap', ...newIngredient('Seife', 'Drogerie') },
];

describe('groupShoppingItems', () => {
  it('fasst pro Zutat und Dimension zusammen', () => {
    const { open } = groupShoppingItems(
      [
        item('i1', 'parsley', { amount: 200, unit: 'g' }),
        item('i2', 'parsley', { amount: 1, unit: 'bund' }),
        item('i3', 'milk', { amount: 1000, unit: 'ml' }),
        item('i4', 'milk', { amount: 500, unit: 'ml' }),
      ],
      catalog,
    );
    expect(open.map((g) => [g.name, formatTotals(g.totals)])).toEqual([
      ['Petersilie', '200 g + 1 Bund'],
      ['Milch', '1,5 l'],
    ]);
  });

  it('sortiert nach Kategorie, dann Name', () => {
    const { open } = groupShoppingItems(
      [item('i1', 'soap'), item('i2', 'milk'), item('i3', 'parsley'), item('i4', 'apple')],
      catalog,
    );
    expect(open.map((g) => g.name)).toEqual(['Apfel', 'Petersilie', 'Milch', 'Seife']);
  });

  it('trennt abgehakte von offenen Einträgen derselben Zutat', () => {
    const { open, done } = groupShoppingItems(
      [item('i1', 'milk', { amount: 1000, unit: 'ml', checkedAt: ts(5) }), item('i2', 'milk', { amount: 500, unit: 'ml' })],
      catalog,
    );
    expect(open).toHaveLength(1);
    expect(open[0].items.map((i) => i.id)).toEqual(['i2']);
    expect(done[0].items.map((i) => i.id)).toEqual(['i1']);
  });

  it('zeigt keine Summe für Einträge ohne Menge', () => {
    const { open } = groupShoppingItems([item('i1', 'milk')], catalog);
    expect(formatTotals(open[0].totals)).toBe('');
  });
});
