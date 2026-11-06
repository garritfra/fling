import type { Unit } from '../../schema';
import { toBaseUnit } from './units';

/**
 * Gemeinsamer Parser für Freitext-Zeilen ("2 l Milch", "1 Bund Petersilie", "500g Mehl (Type 405)").
 * Wird von der Einkaufsliste und später vom Rezept-Import verwendet.
 *
 * Mengen werden in Basiseinheit zurückgegeben (kg -> g, l -> ml).
 * Eine Menge ohne Einheit ("3 Eier") wird als Stück interpretiert.
 */
export interface ParsedLine {
  amount?: number;
  unit?: Unit;
  name: string;
  /** Klammerzusatz oder Text nach dem ersten Komma ("fein gehackt"). */
  note?: string;
}

/** Schreibweisen -> Einheit. `factor` rechnet Nicht-Standard-Einheiten (cl, dl) in die Zieleinheit um. */
const unitSynonyms: Record<string, { unit: Unit; factor?: number }> = {
  g: { unit: 'g' },
  gr: { unit: 'g' },
  gramm: { unit: 'g' },
  kg: { unit: 'kg' },
  kilo: { unit: 'kg' },
  kilogramm: { unit: 'kg' },
  ml: { unit: 'ml' },
  milliliter: { unit: 'ml' },
  cl: { unit: 'ml', factor: 10 },
  dl: { unit: 'ml', factor: 100 },
  l: { unit: 'l' },
  ltr: { unit: 'l' },
  liter: { unit: 'l' },
  stk: { unit: 'stk' },
  stck: { unit: 'stk' },
  st: { unit: 'stk' },
  'stück': { unit: 'stk' },
  x: { unit: 'stk' },
  bund: { unit: 'bund' },
  bd: { unit: 'bund' },
  dose: { unit: 'dose' },
  dosen: { unit: 'dose' },
  ds: { unit: 'dose' },
  packung: { unit: 'packung' },
  packungen: { unit: 'packung' },
  pck: { unit: 'packung' },
  pkg: { unit: 'packung' },
  pack: { unit: 'packung' },
  'päckchen': { unit: 'packung' },
  el: { unit: 'el' },
  'esslöffel': { unit: 'el' },
  'eßlöffel': { unit: 'el' },
  tbsp: { unit: 'el' },
  tl: { unit: 'tl' },
  'teelöffel': { unit: 'tl' },
  tsp: { unit: 'tl' },
  prise: { unit: 'prise' },
  prisen: { unit: 'prise' },
};

const unicodeFractions: Record<string, string> = {
  '½': '1/2',
  '⅓': '1/3',
  '⅔': '2/3',
  '¼': '1/4',
  '¾': '3/4',
  '⅛': '1/8',
};

// Einzelne Zahl: "2", "1,5", "1.5", "1/2", "1 1/2"
const NUM = String.raw`\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?`;
// Optional Bereich: "2-3", "2 – 3", "2 bis 3" (die obere Grenze zählt)
const QUANTITY = String.raw`(${NUM})(?:\s*(?:-|–|bis)\s*(${NUM}))?`;
// Einheit: Buchstaben, optional mit Punkt ("Pck.", "Essl.")
const UNIT = String.raw`([a-zäöüß]+\.?)`;

const leading = new RegExp(String.raw`^${QUANTITY}(\s*)(?:${UNIT}(?=\s|$))?\s*(.*)$`, 'iu');
const trailing = new RegExp(String.raw`^(.*?)\s+${QUANTITY}\s*(?:${UNIT})?$`, 'iu');

function parseNumber(token: string): number {
  const t = token.trim();
  const mixed = t.match(/^(\d+)\s+(\d+)\/(\d+)$/);
  if (mixed) return Number(mixed[1]) + Number(mixed[2]) / Number(mixed[3]);
  const fraction = t.match(/^(\d+)\/(\d+)$/);
  if (fraction) return Number(fraction[1]) / Number(fraction[2]);
  return Number(t.replace(',', '.'));
}

function lookupUnit(token: string | undefined): { unit: Unit; factor?: number } | undefined {
  if (!token) return undefined;
  return unitSynonyms[token.toLowerCase().replace(/\.$/, '')];
}

function splitNote(rest: string): { name: string; note?: string } {
  const notes: string[] = [];
  let name = rest.replace(/\(([^)]*)\)/g, (_, inner: string) => {
    notes.push(inner.trim());
    return ' ';
  });
  const comma = name.indexOf(',');
  if (comma >= 0) {
    notes.push(name.slice(comma + 1).trim());
    name = name.slice(0, comma);
  }
  name = name.replace(/\s+/g, ' ').trim();
  const note = notes.filter(Boolean).join(', ');
  return note ? { name, note } : { name };
}

function finish(quantity: string, upper: string | undefined, unitToken: string | undefined, rest: string): ParsedLine | undefined {
  const raw = parseNumber(upper ?? quantity);
  if (!Number.isFinite(raw) || raw <= 0) return undefined;
  const found = lookupUnit(unitToken);
  // Ein Wort nach der Zahl, das keine Einheit ist, gehört zum Namen ("3 Eier").
  const restWithWord = found || !unitToken ? rest : `${unitToken} ${rest}`;
  const { name, note } = splitNote(restWithWord);
  const base = toBaseUnit(raw * (found?.factor ?? 1), found?.unit ?? 'stk');
  return { amount: base.amount, unit: base.unit, name, ...(note ? { note } : {}) };
}

export function parseIngredientLine(input: string): ParsedLine {
  let line = input.trim().replace(/\s+/g, ' ');
  for (const [symbol, replacement] of Object.entries(unicodeFractions)) {
    line = line.replace(new RegExp(String.raw`(\d)?\s*${symbol}`, 'g'), (_, whole?: string) =>
      whole ? `${whole} ${replacement}` : replacement,
    );
  }

  const lead = line.match(leading);
  // "7up": direkt an der Zahl klebendes Wort, das keine Einheit ist -> ganze Zeile ist der Name.
  const glued = lead && lead[4] && lead[3] === '' && !lookupUnit(lead[4]);
  if (lead && !glued) {
    const result = finish(lead[1], lead[2], lead[4], lead[5]);
    if (result) return result;
  }

  // "Milch 2 l", "Eier 10"
  const trail = line.match(trailing);
  if (trail && trail[1].trim()) {
    const unitToken = trail[4];
    if (!unitToken || lookupUnit(unitToken)) {
      const result = finish(trail[2], trail[3], unitToken, trail[1]);
      if (result) return result;
    }
  }

  return splitNote(line);
}
