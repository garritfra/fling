import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { GoogleAuthProvider, signInWithCredential, signOut as firebaseSignOut } from '@react-native-firebase/auth';
import Constants from 'expo-constants';
import { auth } from './firebase';

// Nur Google Sign-In. Die Web-Client-ID stammt aus google-services.json (siehe app.config.ts).
GoogleSignin.configure({
  webClientId: Constants.expoConfig?.extra?.googleWebClientId,
});

/** Liefert false, wenn der Nutzer den Dialog abbricht. */
export async function signInWithGoogle(): Promise<boolean> {
  await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
  const response = await GoogleSignin.signIn();
  if (response.type !== 'success') return false;
  const credential = GoogleAuthProvider.credential(response.data.idToken);
  await signInWithCredential(auth, credential);
  return true;
}

export async function signOut(): Promise<void> {
  await GoogleSignin.signOut();
  await firebaseSignOut(auth);
}
