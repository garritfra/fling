import { describe, expect, it } from 'vitest';
import { formatAmount } from '../../src/lib/units';

describe('formatAmount', () => {
  it.each([
    [1500, 'g', '1,5 kg'],
    [1000, 'g', '1 kg'],
    [250, 'g', '250 g'],
    [2.5, 'g', '2,5 g'],
    [2000, 'ml', '2 l'],
    [330, 'ml', '330 ml'],
    [2, 'dose', '2 Dosen'],
    [1, 'dose', '1 Dose'],
    [0.5, 'tl', '0,5 TL'],
    [3, 'stk', '3 Stk.'],
  ] as const)('%d %s -> %s', (amount, unit, expected) => {
    expect(formatAmount(amount, unit)).toBe(expected);
  });
});
