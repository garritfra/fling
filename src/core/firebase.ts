import { getApp } from '@react-native-firebase/app';
import { connectAuthEmulator, getAuth } from '@react-native-firebase/auth';
import { connectFirestoreEmulator, initializeFirestore } from '@react-native-firebase/firestore';

// Offline-Persistenz ist in react-native-firebase standardmäßig aktiv.
export const auth = getAuth();
export const db = initializeFirestore(getApp(), { ignoreUndefinedProperties: true });

if (process.env.EXPO_PUBLIC_USE_EMULATOR === 'true') {
  // 10.0.2.2 ist der Host-Rechner aus Sicht des Android-Emulators.
  const host = process.env.EXPO_PUBLIC_EMULATOR_HOST ?? '10.0.2.2';
  connectAuthEmulator(auth, `http://${host}:9099`);
  connectFirestoreEmulator(db, host, 8080);
}

/**
 * Schreibvorgänge im UI nicht awaiten: Das Promise löst erst nach Server-Bestätigung auf und
 * hängt offline. Lokaler Cache und Listener zeigen die Änderung sofort. Fehler (z. B. von den
 * Security Rules) werden nur protokolliert.
 */
export function fireAndForget(write: Promise<unknown>): void {
  write.catch((error) => console.warn('Firestore-Schreibvorgang fehlgeschlagen', error));
}
