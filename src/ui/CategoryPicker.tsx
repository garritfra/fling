import { StyleSheet, View } from 'react-native';
import { categories } from '../lib/categories';
import { Chip } from './components';
import { spacing } from './theme';

export function CategoryPicker({ value, onChange }: { value?: string; onChange: (category: string) => void }) {
  return (
    <View style={styles.wrap}>
      {categories.map((c) => (
        <Chip key={c} label={c} selected={c === value} onPress={() => onChange(c)} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({ wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.s } });
