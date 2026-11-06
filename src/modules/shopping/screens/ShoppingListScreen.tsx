import { Ionicons } from '@expo/vector-icons';
import { Link } from 'expo-router';
import { useMemo, useState } from 'react';
import { Modal, Pressable, SectionList, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { createIngredient, useIngredients } from '../../../catalog/api';
import { useReadySession } from '../../../core/session';
import { findIngredient } from '../../../lib/catalog';
import { parseIngredientLine, type ParsedLine } from '../../../lib/parseIngredientLine';
import { formatAmount } from '../../../lib/units';
import { CategoryPicker } from '../../../ui/CategoryPicker';
import { Button, Input } from '../../../ui/components';
import { colors, spacing } from '../../../ui/theme';
import { addShoppingItems, deleteShoppingItems, setChecked, useShoppingItems } from '../api';
import { formatTotals, groupShoppingItems, type ShoppingGroup } from '../grouping';

interface Section {
  title: string;
  done: boolean;
  data: ShoppingGroup[];
}

export function ShoppingListScreen() {
  const { household, me, people } = useReadySession();
  const hid = household.id;
  const ingredients = useIngredients(hid);
  const items = useShoppingItems(hid);

  const [text, setText] = useState('');
  const [expanded, setExpanded] = useState<string | null>(null);
  /** Eingabe ohne Katalog-Treffer: Kategorie für die neue Zutat wird einmalig abgefragt. */
  const [pending, setPending] = useState<ParsedLine | null>(null);

  const { open, done } = useMemo(() => groupShoppingItems(items.data, ingredients.data), [items.data, ingredients.data]);

  const sections = useMemo(() => {
    const byCategory = new Map<string, ShoppingGroup[]>();
    for (const group of open) {
      byCategory.set(group.category, [...(byCategory.get(group.category) ?? []), group]);
    }
    const result: Section[] = [...byCategory.entries()].map(([title, data]) => ({ title, done: false, data }));
    if (done.length > 0) result.push({ title: 'Erledigt', done: true, data: done });
    return result;
  }, [open, done]);

  const personName = (personId: string) => people.find((p) => p.id === personId)?.displayName ?? 'Unbekannt';

  function add(parsed: ParsedLine, ingredientId: string) {
    addShoppingItems(hid, [{ ingredientId, amount: parsed.amount, unit: parsed.unit }], { type: 'manual' }, me.id);
  }

  function submit() {
    const parsed = parseIngredientLine(text);
    if (!parsed.name) return;
    const match = findIngredient(parsed.name, ingredients.data);
    if (match) add(parsed, match.id);
    else setPending(parsed);
    setText('');
  }

  function createAndAdd(category: string) {
    if (!pending) return;
    add(pending, createIngredient(hid, pending.name, category));
    setPending(null);
  }

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <View style={styles.header}>
        <Text style={styles.title}>Einkaufsliste</Text>
        <Link href="/catalog" asChild>
          <Pressable hitSlop={12} accessibilityLabel="Katalog">
            <Ionicons name="pricetags-outline" size={22} color={colors.text} />
          </Pressable>
        </Link>
      </View>

      <View style={styles.inputRow}>
        <Input
          style={styles.input}
          value={text}
          onChangeText={setText}
          placeholder="Was fehlt? z. B. 2 l Milch"
          returnKeyType="done"
          submitBehavior="submit"
          onSubmitEditing={submit}
        />
      </View>

      <SectionList
        sections={sections}
        keyExtractor={(group) => group.ingredientId}
        contentContainerStyle={styles.list}
        stickySectionHeadersEnabled={false}
        ListEmptyComponent={
          items.loaded ? <Text style={styles.empty}>Die Liste ist leer.</Text> : undefined
        }
        renderSectionHeader={({ section }) => (
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>{section.title}</Text>
            {section.done && (
              <Pressable
                hitSlop={8}
                onPress={() => deleteShoppingItems(hid, section.data.flatMap((g) => g.items))}
              >
                <Text style={styles.clear}>Erledigte leeren</Text>
              </Pressable>
            )}
          </View>
        )}
        renderItem={({ item: group, section }) => {
          const key = `${section.done ? 'done' : 'open'}:${group.ingredientId}`;
          const isExpanded = expanded === key;
          return (
            <View style={styles.row}>
              <View style={styles.rowMain}>
                <Pressable
                  hitSlop={8}
                  accessibilityRole="checkbox"
                  accessibilityState={{ checked: section.done }}
                  onPress={() => setChecked(hid, group.items, !section.done, me.id)}
                >
                  <Ionicons
                    name={section.done ? 'checkmark-circle' : 'ellipse-outline'}
                    size={26}
                    color={section.done ? colors.muted : colors.primary}
                  />
                </Pressable>
                <Pressable style={styles.rowText} onPress={() => setExpanded(isExpanded ? null : key)}>
                  <Text style={[styles.name, section.done && styles.doneText]}>{group.name}</Text>
                  <Text style={styles.amount}>{formatTotals(group.totals)}</Text>
                </Pressable>
              </View>
              {isExpanded &&
                group.items.map((item) => (
                  <View key={item.id} style={styles.source}>
                    <Text style={styles.sourceText}>
                      {item.amount !== undefined && item.unit ? `${formatAmount(item.amount, item.unit)} · ` : ''}
                      {item.source.type === 'manual' ? 'Manuell' : 'Wochenplan'} · {personName(item.createdBy)}
                    </Text>
                    <Pressable hitSlop={8} onPress={() => deleteShoppingItems(hid, [item])} accessibilityLabel="Löschen">
                      <Ionicons name="trash-outline" size={18} color={colors.danger} />
                    </Pressable>
                  </View>
                ))}
            </View>
          );
        }}
      />

      <Modal visible={pending !== null} transparent animationType="slide" onRequestClose={() => setPending(null)}>
        <View style={styles.backdrop}>
          <View style={styles.sheet}>
            <Text style={styles.sheetTitle}>„{pending?.name}“ ist neu</Text>
            <Text style={styles.sheetText}>In welcher Kategorie findest du es?</Text>
            <CategoryPicker onChange={createAndAdd} />
            <Button title="Abbrechen" variant="secondary" onPress={() => setPending(null)} />
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.l,
    paddingTop: spacing.m,
  },
  title: { fontSize: 28, fontWeight: '700', color: colors.text },
  inputRow: { padding: spacing.l },
  input: { fontSize: 17 },
  list: { paddingHorizontal: spacing.l, paddingBottom: 120 },
  empty: { textAlign: 'center', color: colors.muted, marginTop: spacing.xl },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing.l,
    marginBottom: spacing.s,
  },
  sectionTitle: { fontSize: 13, fontWeight: '600', color: colors.muted, textTransform: 'uppercase' },
  clear: { color: colors.primary, fontWeight: '600' },
  row: {
    backgroundColor: colors.surface,
    borderRadius: 10,
    marginBottom: spacing.xs,
    paddingHorizontal: spacing.m,
    paddingVertical: spacing.m,
  },
  rowMain: { flexDirection: 'row', alignItems: 'center', gap: spacing.m },
  rowText: { flex: 1, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  name: { fontSize: 17, color: colors.text, flexShrink: 1 },
  doneText: { color: colors.muted, textDecorationLine: 'line-through' },
  amount: { fontSize: 15, color: colors.muted, marginLeft: spacing.s },
  source: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing.s,
    marginLeft: 38,
  },
  sourceText: { color: colors.muted, flexShrink: 1 },
  backdrop: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.3)' },
  sheet: {
    backgroundColor: colors.background,
    padding: spacing.xl,
    gap: spacing.l,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
  },
  sheetTitle: { fontSize: 20, fontWeight: '700', color: colors.text },
  sheetText: { color: colors.muted },
});
