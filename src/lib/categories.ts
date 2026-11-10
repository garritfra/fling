/**
 * Kategorien in Laufreihenfolge durch den Supermarkt. Die Einkaufsliste sortiert danach.
 * (Offener Punkt der Spezifikation: global oder pro Laden – vorerst global.)
 */
export const categories = [
  'Obst & Gemüse',
  'Brot & Backwaren',
  'Kühlregal',
  'Fleisch & Fisch',
  'Tiefkühl',
  'Vorrat',
  'Gewürze & Backen',
  'Süßes & Snacks',
  'Getränke',
  'Drogerie',
  'Haushalt',
  'Sonstiges',
] as const;

export function categoryIndex(category: string): number {
  const index = (categories as readonly string[]).indexOf(category);
  return index === -1 ? categories.length : index;
}
