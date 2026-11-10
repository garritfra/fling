import { describe, expect, it } from 'vitest';
import { parseIngredientLine } from '../../src/lib/parseIngredientLine';

describe('parseIngredientLine', () => {
  it.each([
    ['2 l Milch', { amount: 2000, unit: 'ml', name: 'Milch' }],
    ['500g Mehl', { amount: 500, unit: 'g', name: 'Mehl' }],
    ['1,5 kg Kartoffeln', { amount: 1500, unit: 'g', name: 'Kartoffeln' }],
    ['1.5 kg Kartoffeln', { amount: 1500, unit: 'g', name: 'Kartoffeln' }],
    ['3 Eier', { amount: 3, unit: 'stk', name: 'Eier' }],
    ['1 Bund Petersilie', { amount: 1, unit: 'bund', name: 'Petersilie' }],
    ['1 Pck. Backpulver', { amount: 1, unit: 'packung', name: 'Backpulver' }],
    ['2 Dosen Tomaten', { amount: 2, unit: 'dose', name: 'Tomaten' }],
    ['1/2 TL Salz', { amount: 0.5, unit: 'tl', name: 'Salz' }],
    ['½ Zitrone', { amount: 0.5, unit: 'stk', name: 'Zitrone' }],
    ['1½ EL Öl', { amount: 1.5, unit: 'el', name: 'Öl' }],
    ['1 1/2 Tassen Reis', { amount: 1.5, unit: 'stk', name: 'Tassen Reis' }],
    ['2-3 Zwiebeln', { amount: 3, unit: 'stk', name: 'Zwiebeln' }],
    ['1 Prise Salz', { amount: 1, unit: 'prise', name: 'Salz' }],
    ['2 cl Rum', { amount: 20, unit: 'ml', name: 'Rum' }],
    ['2x Joghurt', { amount: 2, unit: 'stk', name: 'Joghurt' }],
    ['Milch 2l', { amount: 2000, unit: 'ml', name: 'Milch' }],
    ['Eier 10', { amount: 10, unit: 'stk', name: 'Eier' }],
    ['Brot', { name: 'Brot' }],
    ['  rote   Linsen ', { name: 'rote Linsen' }],
    ['7up', { name: '7up' }],
  ])('%s', (input, expected) => {
    expect(parseIngredientLine(input)).toEqual(expected);
  });

  it('trennt Zusätze ab', () => {
    expect(parseIngredientLine('200 g Mehl (Type 405)')).toEqual({ amount: 200, unit: 'g', name: 'Mehl', note: 'Type 405' });
    expect(parseIngredientLine('1 Zwiebel, fein gewürfelt')).toEqual({
      amount: 1,
      unit: 'stk',
      name: 'Zwiebel',
      note: 'fein gewürfelt',
    });
  });

  it('liefert einen leeren Namen, wenn nur eine Menge angegeben ist', () => {
    expect(parseIngredientLine('2 l')).toEqual({ amount: 2000, unit: 'ml', name: '' });
  });
});
