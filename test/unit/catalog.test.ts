import { describe, expect, it } from 'vitest';
import type { Ingredient, WithId } from '../../schema';
import { findIngredient, mergedAliases, newIngredient, normalizeName } from '../../src/lib/catalog';

const ing = (id: string, name: string, aliases: string[] = []): WithId<Ingredient> => ({
  id,
  ...newIngredient(name, 'Sonstiges'),
  aliases,
});

describe('Katalog-Abgleich', () => {
  const catalog = [ing('milk', 'Milch'), ing('tomato', 'Tomaten'), ing('onion', 'Zwiebel'), ing('egg', 'Ei', ['eier'])];

  it('normalisiert Namen', () => {
    expect(normalizeName('  Rote   LINSEN ')).toBe('rote linsen');
  });

  it('findet über Name und Alias', () => {
    expect(findIngredient('milch', catalog)?.id).toBe('milk');
    expect(findIngredient('Eier', catalog)?.id).toBe('egg');
  });

  it('gleicht Singular und Plural an', () => {
    expect(findIngredient('Tomate', catalog)?.id).toBe('tomato');
    expect(findIngredient('Zwiebeln', catalog)?.id).toBe('onion');
  });

  it('liefert nichts ohne Treffer', () => {
    expect(findIngredient('Butter', catalog)).toBeUndefined();
    expect(findIngredient('', catalog)).toBeUndefined();
  });

  it('macht beim Zusammenführen die Quelle zum Alias', () => {
    const target = ing('a', 'Paprika', ['spitzpaprika']);
    const source = ing('b', 'Paprikaschote', ['paprika']);
    expect(mergedAliases(target, source).sort()).toEqual(['paprikaschote', 'spitzpaprika']);
  });
});
