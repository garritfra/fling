import { useMemo, useState } from 'react';
import { Modal, Pressable, ScrollView, SectionList, StyleSheet, Text, View } from 'react-native';
import type { Ingredient, WithId } from '../../../../schema';
import { mergeIngredientInto, updateIngredient, useIngredients } from '../../../catalog/api';
import { useReadySession } from '../../../core/session';
import { categoryIndex } from '../../../lib/categories';
import { normalizeName } from '../../../lib/catalog';
import { CategoryPicker } from '../../../ui/CategoryPicker';
import { Button, Input, Section } from '../../../ui/components';
import { colors, spacing } from '../../../ui/theme';
import { reassignIngredient, useShoppingItems } from '../api';

/** Zutaten-Katalog: Kategorie ändern, umbenennen, Duplikate zusammenführen. */
export function CatalogScreen() {
  const { household } = useReadySession();
  const hid = household.id;
  const ingredients = useIngredients(hid);
  const items = useShoppingItems(hid);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const selected = ingredients.data.find((i) => i.id === selectedId);

  const sections = useMemo(() => {
    const byCategory = new Map<string, WithId<Ingredient>[]>();
    for (const ingredient of ingredients.data) {
      byCategory.set(ingredient.category, [...(byCategory.get(ingredient.category) ?? []), ingredient]);
    }
    return [...byCategory.entries()]
      .sort(([a], [b]) => categoryIndex(a) - categoryIndex(b))
      .map(([title, data]) => ({ title, data: data.sort((a, b) => a.name.localeCompare(b.name, 'de')) }));
  }, [ingredients.data]);

  function merge(target: WithId<Ingredient>, source: WithId<Ingredient>) {
    // Erst die Einträge der Einkaufsliste umhängen (über deren Schnittstelle), dann zusammenführen.
    reassignIngredient(hid, items.data, source.id, target.id);
    mergeIngredientInto(hid, target, source);
    setSelectedId(null);
  }

  return (
    <View style={styles.screen}>
      <SectionList
        sections={sections}
        keyExtractor={(i) => i.id}
        contentContainerStyle={styles.list}
        stickySectionHeadersEnabled={false}
        ListEmptyComponent={
          ingredients.loaded ? (
            <Text style={styles.empty}>Noch keine Zutaten. Sie entstehen beim Hinzufügen zur Liste.</Text>
          ) : undefined
        }
        renderSectionHeader={({ section }) => <Text style={styles.sectionTitle}>{section.title}</Text>}
        renderItem={({ item }) => (
          <Pressable style={styles.row} onPress={() => setSelectedId(item.id)}>
            <Text style={styles.name}>{item.name}</Text>
            {item.aliases.length > 0 && <Text style={styles.aliases}>auch: {item.aliases.join(', ')}</Text>}
          </Pressable>
        )}
      />
      {selected && (
        <IngredientEditor
          key={selected.id}
          ingredient={selected}
          catalog={ingredients.data}
          onClose={() => setSelectedId(null)}
          onSave={(changes) => {
            updateIngredient(hid, selected.id, changes);
            setSelectedId(null);
          }}
          onMergeInto={(target) => merge(target, selected)}
        />
      )}
    </View>
  );
}

function IngredientEditor({
  ingredient,
  catalog,
  onClose,
  onSave,
  onMergeInto,
}: {
  ingredient: WithId<Ingredient>;
  catalog: WithId<Ingredient>[];
  onClose: () => void;
  onSave: (changes: { name: string; category: string }) => void;
  onMergeInto: (target: WithId<Ingredient>) => void;
}) {
  const [name, setName] = useState(ingredient.name);
  const [category, setCategory] = useState(ingredient.category);
  const [filter, setFilter] = useState('');

  const candidates = useMemo(() => {
    const f = normalizeName(filter);
    if (!f) return [];
    return catalog.filter((i) => i.id !== ingredient.id && i.nameNormalized.includes(f)).slice(0, 8);
  }, [catalog, filter, ingredient.id]);

  return (
    <Modal visible transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.backdrop}>
        <ScrollView style={styles.sheet} contentContainerStyle={styles.sheetContent} keyboardShouldPersistTaps="handled">
          <Section title="Name">
            <Input value={name} onChangeText={setName} />
          </Section>
          <Section title="Kategorie">
            <CategoryPicker value={category} onChange={setCategory} />
          </Section>
          <Button
            title="Speichern"
            disabled={!name.trim()}
            onPress={() => onSave({ name: name.trim(), category })}
          />
          <Section title="Zusammenführen mit …">
            <Text style={styles.hint}>
              „{ingredient.name}“ wird zum Alias der gewählten Zutat. Einträge auf der Liste werden übernommen.
            </Text>
            <Input value={filter} onChangeText={setFilter} placeholder="Zutat suchen" />
            {candidates.map((c) => (
              <Pressable key={c.id} style={styles.candidate} onPress={() => onMergeInto(c)}>
                <Text style={styles.name}>{c.name}</Text>
                <Text style={styles.aliases}>{c.category}</Text>
              </Pressable>
            ))}
          </Section>
          <Button title="Abbrechen" variant="secondary" onPress={onClose} />
        </ScrollView>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  list: { padding: spacing.l },
  empty: { textAlign: 'center', color: colors.muted, marginTop: spacing.xl },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.muted,
    textTransform: 'uppercase',
    marginTop: spacing.l,
    marginBottom: spacing.s,
  },
  row: { backgroundColor: colors.surface, borderRadius: 10, padding: spacing.m, marginBottom: spacing.xs },
  name: { fontSize: 17, color: colors.text },
  aliases: { fontSize: 13, color: colors.muted, marginTop: 2 },
  backdrop: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.3)' },
  sheet: { maxHeight: '90%', backgroundColor: colors.background, borderTopLeftRadius: 16, borderTopRightRadius: 16 },
  sheetContent: { padding: spacing.xl, gap: spacing.l },
  hint: { color: colors.muted },
  candidate: { backgroundColor: colors.surface, borderRadius: 10, padding: spacing.m },
});
