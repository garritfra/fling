import Constants from 'expo-constants';
import { router } from 'expo-router';
import { useState } from 'react';
import { Alert, ScrollView, Share, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { Invite, WithId } from '../../../schema';
import { Button, Input, Section } from '../../ui/components';
import { colors, spacing } from '../../ui/theme';
import { signOut } from '../auth';
import { addPerson, createInvite, renameHousehold, renamePerson } from '../household';
import { useReadySession } from '../session';

export function HouseholdScreen() {
  const { user, household, me, people } = useReadySession();
  const [name, setName] = useState(household.name);
  const [guestName, setGuestName] = useState('');
  const [invite, setInvite] = useState<WithId<Invite> | null>(null);
  const [inviting, setInviting] = useState(false);

  async function invitePerson() {
    setInviting(true);
    try {
      setInvite(await createInvite(household.id, user.uid));
    } catch {
      Alert.alert('Einladung fehlgeschlagen', 'Zum Einladen wird eine Internetverbindung benötigt.');
    } finally {
      setInviting(false);
    }
  }

  const expiresAt = invite
    ? new Date(invite.expiresAt.toMillis()).toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' })
    : '';

  return (
    <SafeAreaView style={styles.screen} edges={['top']}>
      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <Text style={styles.title}>Haushalt</Text>

        <Section title="Name">
          <Input
            value={name}
            onChangeText={setName}
            onEndEditing={() => name.trim() && name !== household.name && renameHousehold(household.id, name.trim())}
          />
        </Section>

        <Section title="Personen">
          {people.map((person) => (
            <View key={person.id} style={styles.personRow}>
              <Input
                style={styles.personName}
                defaultValue={person.displayName}
                onEndEditing={(e) => {
                  const value = e.nativeEvent.text.trim();
                  if (value && value !== person.displayName) renamePerson(household.id, person.id, value);
                }}
              />
              <Text style={styles.badge}>{person.id === me.id ? 'du' : person.uid ? 'Mitglied' : 'Gast'}</Text>
            </View>
          ))}
          <View style={styles.personRow}>
            <Input
              style={styles.personName}
              value={guestName}
              onChangeText={setGuestName}
              placeholder="Gast ohne App hinzufügen"
            />
            <Button
              title="Hinzufügen"
              variant="secondary"
              disabled={!guestName.trim()}
              onPress={() => {
                addPerson(household.id, { displayName: guestName.trim() });
                setGuestName('');
              }}
            />
          </View>
        </Section>

        <Section title="Einladen">
          {invite ? (
            <View style={styles.invite}>
              <Text style={styles.code} selectable>
                {invite.id}
              </Text>
              <Text style={styles.muted}>Gültig bis {expiresAt} Uhr, einmal verwendbar.</Text>
              <Button
                title="Code teilen"
                onPress={() =>
                  Share.share({
                    message: `Tritt unserem Haushalt in Fling bei: Code ${invite.id} (gültig bis ${expiresAt} Uhr)`,
                  })
                }
              />
            </View>
          ) : (
            <Button title="Einladungscode erstellen" loading={inviting} onPress={invitePerson} />
          )}
          <Button title="Mit Code beitreten" variant="secondary" onPress={() => router.push('/join')} />
        </Section>

        <Section title="Konto">
          <Text style={styles.muted}>{user.email}</Text>
          <Button title="Abmelden" variant="danger" onPress={() => signOut()} />
        </Section>

        <Text style={styles.footer}>
          Fling {Constants.expoConfig?.version} · {String(Constants.expoConfig?.extra?.variant)}
        </Text>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  content: { padding: spacing.l, paddingBottom: 80 },
  title: { fontSize: 28, fontWeight: '700', color: colors.text, marginBottom: spacing.l },
  personRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.s },
  personName: { flex: 1 },
  badge: { color: colors.muted, minWidth: 64, textAlign: 'right' },
  invite: { alignItems: 'center', gap: spacing.m, padding: spacing.l, backgroundColor: colors.surface, borderRadius: 10 },
  code: { fontSize: 40, fontWeight: '700', letterSpacing: 6, color: colors.text, fontVariant: ['tabular-nums'] },
  muted: { color: colors.muted },
  footer: { color: colors.muted, textAlign: 'center', fontSize: 12 },
});
