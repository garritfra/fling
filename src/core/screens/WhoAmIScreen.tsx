import { ScrollView, StyleSheet, Text } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Button, Section } from '../../ui/components';
import { colors, spacing } from '../../ui/theme';
import { addPerson, claimPerson } from '../household';
import { useSession } from '../session';

/**
 * Nach dem Beitritt: Gibt es die Person schon (z. B. als Gast angelegt), wird der Account mit ihr
 * verknüpft – alle bisherigen Einträge gehören damit automatisch ihr. Sonst entsteht eine neue Person.
 */
export function WhoAmIScreen() {
  const { user, household, people } = useSession();
  if (!user || !household) return null;
  const guests = people.filter((p) => !p.uid);
  const ownName = user.displayName?.split(' ')[0] || 'Ich';

  return (
    <SafeAreaView style={styles.screen}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Willkommen in „{household.name}“</Text>
        {guests.length > 0 && (
          <Section title="Bist du schon eingetragen?">
            {guests.map((guest) => (
              <Button
                key={guest.id}
                title={`Ich bin ${guest.displayName}`}
                variant="secondary"
                onPress={() => claimPerson(household.id, guest.id, user.uid)}
              />
            ))}
          </Section>
        )}
        <Button
          title={`Neu als ${ownName}`}
          onPress={() => addPerson(household.id, { displayName: ownName, uid: user.uid })}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.xl, gap: spacing.l },
  title: { fontSize: 24, fontWeight: '700', color: colors.text },
});
