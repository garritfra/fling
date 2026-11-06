import { units, type Unit } from '../../schema';

/**
 * Umrechnung nur innerhalb einer Dimension: Masse (g <-> kg), Volumen (ml <-> l).
 * Gespeichert wird immer in Basiseinheit (g, ml); alle anderen Einheiten werden nie umgerechnet.
 */
export function toBaseUnit(amount: number, unit: Unit): { amount: number; unit: Unit } {
  switch (unit) {
    case 'kg':
      return { amount: amount * 1000, unit: 'g' };
    case 'l':
      return { amount: amount * 1000, unit: 'ml' };
    default:
      return { amount, unit };
  }
}

/** Reihenfolge, in der Teilsummen angezeigt werden. */
export function unitSortIndex(unit: Unit): number {
  return units.indexOf(unit);
}

/** 1.5 -> "1,5", 0.333 -> "0,33" */
export function formatNumber(n: number): string {
  const rounded = Math.round(n * 100) / 100;
  return String(rounded).replace('.', ',');
}

const labels: Record<Unit, [singular: string, plural: string]> = {
  g: ['g', 'g'],
  kg: ['kg', 'kg'],
  ml: ['ml', 'ml'],
  l: ['l', 'l'],
  stk: ['Stk.', 'Stk.'],
  bund: ['Bund', 'Bund'],
  dose: ['Dose', 'Dosen'],
  packung: ['Pkg.', 'Pkg.'],
  el: ['EL', 'EL'],
  tl: ['TL', 'TL'],
  prise: ['Prise', 'Prisen'],
};

/** Sinnvoll gerundete Anzeige: 1500 g -> "1,5 kg", 250 ml -> "250 ml", 2 dose -> "2 Dosen". */
export function formatAmount(amount: number, unit: Unit): string {
  let value = amount;
  let displayUnit: Unit = unit;
  if (unit === 'g' && amount >= 1000) {
    value = amount / 1000;
    displayUnit = 'kg';
  } else if (unit === 'ml' && amount >= 1000) {
    value = amount / 1000;
    displayUnit = 'l';
  } else if (unit === 'g' || unit === 'ml') {
    value = amount >= 10 ? Math.round(amount) : amount;
  }
  const [singular, plural] = labels[displayUnit];
  return `${formatNumber(value)} ${value === 1 ? singular : plural}`;
}
