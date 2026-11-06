import { collection, doc } from '@react-native-firebase/firestore';
import { db } from './firebase';

/** Alles liegt unter households/{householdId}/. */
export const householdRef = (householdId: string) => doc(db, 'households', householdId);

export const householdCollection = (householdId: string, name: string) =>
  collection(db, 'households', householdId, name);

export const inviteRef = (code: string) => doc(db, 'invites', code);
