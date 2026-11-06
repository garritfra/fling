import { statusCodes } from '@react-native-google-signin/google-signin';
import { useState } from 'react';
import { Alert, StyleSheet, Text } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Button, Centered } from '../../ui/components';
import { colors } from '../../ui/theme';
import { signInWithGoogle } from '../auth';

export function SignInScreen() {
  const [busy, setBusy] = useState(false);

  async function signIn() {
    setBusy(true);
    try {
      await signInWithGoogle();
    } catch (error) {
      const code = (error as { code?: string }).code;
      if (code !== statusCodes.IN_PROGRESS) {
        Alert.alert('Anmeldung fehlgeschlagen', error instanceof Error ? error.message : String(error));
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <SafeAreaView style={styles.screen}>
      <Centered>
        <Text style={styles.title}>Fling</Text>
        <Text style={styles.subtitle}>Einkaufsliste für euren Haushalt</Text>
        <Button title="Mit Google anmelden" loading={busy} onPress={signIn} style={styles.button} />
      </Centered>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  title: { fontSize: 40, fontWeight: '800', color: colors.primary },
  subtitle: { fontSize: 16, color: colors.muted },
  button: { alignSelf: 'stretch' },
});
