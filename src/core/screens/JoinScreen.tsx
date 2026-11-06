import { useState } from 'react';
import { Alert, StyleSheet, Text, View } from 'react-native';
import { useIngredients } from '../../catalog/api';
import { useShoppingItems } from '../../modules/shopping/api';
import { Button, Input } from '../../ui/components';
import { colors, spacing } from '../../ui/theme';
import { JoinError, joinHousehold, normalizeInviteCode } from '../household';
import { useReadySession } from '../session';

export function JoinScreen() {
  const { user, household, people } = useReadySession();
  const [code, setCode] = useState('');
  const [joining, setJoining] = useState(false);

  // Ein automatisch angelegter, noch leerer Haushalt wird beim Beitritt kommentarlos verworfen.
  const items = useShoppingItems(household.id);
  const ingredients = useIngredients(household.id);
  const isEmpty =
    items.data.length === 0 && ingredients.data.length === 0 && people.length === 1 && household.memberUids.length === 1;

  async function join() {
    setJoining(true);
    try {
      // Danach wechselt die Session den Haushalt; die Routen-Guards im Root-Layout
      // führen automatisch weiter (z. B. zu „Wer bist du?“).
      await joinHousehold(normalizeInviteCode(code), user.uid, household);
    } catch (error) {
      Alert.alert('Beitritt nicht möglich', error instanceof JoinError ? error.message : String(error));
    } finally {
      setJoining(false);
    }
  }

  return (
    <View style={styles.screen}>
      <Text style={styles.text}>Gib den Code ein, den du von einem Mitglied des Haushalts bekommen hast.</Text>
      <Input
        style={styles.code}
        value={code}
        onChangeText={setCode}
        placeholder="ABC123"
        autoCapitalize="characters"
        autoCorrect={false}
        autoFocus
        maxLength={8}
      />
      {!isEmpty && (
        <Text style={styles.warning}>
          Du verlässt dabei „{household.name}“.
          {household.memberUids.length === 1 ? ' Da du das letzte Mitglied bist, wird er gelöscht.' : ''}
        </Text>
      )}
      <Button
        title="Beitreten"
        loading={joining}
        disabled={normalizeInviteCode(code).length < 6}
        onPress={join}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background, padding: spacing.xl, gap: spacing.l },
  text: { fontSize: 16, color: colors.text },
  code: { fontSize: 28, letterSpacing: 6, textAlign: 'center', fontWeight: '700' },
  warning: { color: colors.danger },
});
