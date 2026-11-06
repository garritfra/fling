import {
  Timestamp,
  arrayRemove,
  arrayUnion,
  collection,
  doc,
  getDocFromServer,
  setDoc,
  updateDoc,
  writeBatch,
} from '@react-native-firebase/firestore';
import { Invite, type Household, type Person, type WithId } from '../../schema';
import { db, fireAndForget } from './firebase';
import { householdCollection, householdRef, inviteRef } from './paths';

const defaultModules = ['shopping'];

/** Beim ersten Login: Haushalt mit einer Person für den Nutzer anlegen. */
export function createHousehold(uid: string, displayName: string): void {
  const ref = doc(collection(db, 'households'));
  const household: Household = {
    name: `Haushalt von ${displayName}`,
    memberUids: [uid],
    activeModules: defaultModules,
    createdAt: Timestamp.now(),
  };
  // Zwei getrennte Schreibvorgänge statt Batch: Die Rule für people prüft per get(), dass der
  // Haushalt bereits existiert. Die Reihenfolge bleibt auch offline erhalten.
  fireAndForget(setDoc(ref, household));
  addPerson(ref.id, { displayName, uid });
}

export function renameHousehold(householdId: string, name: string): void {
  fireAndForget(updateDoc(householdRef(householdId), { name }));
}

// ---------------------------------------------------------------------------
// Personen
// ---------------------------------------------------------------------------

export function addPerson(householdId: string, person: Person): string {
  const ref = doc(householdCollection(householdId, 'people'));
  fireAndForget(setDoc(ref, person));
  return ref.id;
}

export function renamePerson(householdId: string, personId: string, displayName: string): void {
  fireAndForget(updateDoc(doc(householdCollection(householdId, 'people'), personId), { displayName }));
}

/** Eine bestehende Person (z. B. Gast) mit dem eigenen Account verknüpfen. Alle Einträge gehören damit ihr. */
export function claimPerson(householdId: string, personId: string, uid: string): void {
  fireAndForget(updateDoc(doc(householdCollection(householdId, 'people'), personId), { uid }));
}

// ---------------------------------------------------------------------------
// Einladungen
// ---------------------------------------------------------------------------

const INVITE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // ohne 0/O und 1/I
const INVITE_LENGTH = 6;
const INVITE_VALIDITY_HOURS = 4;

function randomCode(): string {
  let code = '';
  for (let i = 0; i < INVITE_LENGTH; i++) {
    code += INVITE_ALPHABET[Math.floor(Math.random() * INVITE_ALPHABET.length)];
  }
  return code;
}

export function normalizeInviteCode(input: string): string {
  return input.toUpperCase().replace(/[^A-Z0-9]/g, '');
}

/** Erzeugt einen kurzen Code, gültig für wenige Stunden. Braucht Netz (wird vom Server bestätigt). */
export async function createInvite(householdId: string, uid: string): Promise<WithId<Invite>> {
  const invite: Invite = {
    householdId,
    createdBy: uid,
    expiresAt: Timestamp.fromMillis(Date.now() + INVITE_VALIDITY_HOURS * 3600_000),
  };
  const code = randomCode();
  // Offline würde setDoc nie auflösen – nach kurzer Zeit abbrechen.
  await Promise.race([
    setDoc(inviteRef(code), invite),
    new Promise((_, reject) => setTimeout(() => reject(new Error('Zeitüberschreitung')), 10_000)),
  ]);
  return { ...invite, id: code };
}

export class JoinError extends Error {}

/**
 * Tritt dem Haushalt des Codes bei. Den bisherigen Haushalt verlässt man dabei
 * (MVP: ein Haushalt pro Nutzer); war man dort das letzte Mitglied, wird er soft-gelöscht.
 */
export async function joinHousehold(code: string, uid: string, current: WithId<Household> | undefined): Promise<void> {
  let snapshot;
  try {
    snapshot = await getDocFromServer(inviteRef(code));
  } catch {
    throw new JoinError('Keine Verbindung. Zum Beitreten wird Internet benötigt.');
  }
  const parsed = Invite.safeParse(snapshot.data());
  if (!snapshot.exists() || !parsed.success) throw new JoinError('Diesen Code gibt es nicht.');
  const invite = parsed.data;
  if (invite.usedAt) throw new JoinError('Dieser Code wurde schon verwendet.');
  if (invite.expiresAt.toMillis() < Date.now()) throw new JoinError('Dieser Code ist abgelaufen.');
  if (invite.householdId === current?.id) throw new JoinError('Du bist bereits Mitglied in diesem Haushalt.');

  const batch = writeBatch(db);
  batch.update(householdRef(invite.householdId), { memberUids: arrayUnion(uid), inviteCode: code });
  batch.update(inviteRef(code), { usedAt: Timestamp.now() });
  try {
    await batch.commit();
  } catch {
    throw new JoinError('Beitritt fehlgeschlagen. Ist der Code noch gültig?');
  }

  if (current) leaveHousehold(current, uid);
}

export function leaveHousehold(household: WithId<Household>, uid: string): void {
  const isLastMember = household.memberUids.length <= 1;
  fireAndForget(
    updateDoc(householdRef(household.id), {
      memberUids: arrayRemove(uid),
      ...(isLastMember ? { deletedAt: Timestamp.now() } : {}),
    }),
  );
}
