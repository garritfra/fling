import type { Ionicons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';

/**
 * Modul-Konvention: Ein Modul hat einen Ordner unter src/modules/, eigene Collections unter
 * households/{id}/ und einen Eintrag in household.activeModules. Hier steht, welcher Tab zu
 * welchem Modul gehört. Der Kern (Login, Haushalt, Personen, Navigation) ist immer aktiv.
 */
export interface ModuleDefinition {
  id: string;
  /** Route unter src/app/(tabs)/ */
  route: string;
  title: string;
  icon: ComponentProps<typeof Ionicons>['name'];
}

export const modules: ModuleDefinition[] = [{ id: 'shopping', route: 'index', title: 'Einkauf', icon: 'cart-outline' }];
