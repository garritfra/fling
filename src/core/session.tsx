import { onAuthStateChanged, type User } from '@react-native-firebase/auth';
import { collection, query, where } from '@react-native-firebase/firestore';
import { createContext, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { Household, Person, type WithId } from '../../schema';
import { auth, db } from './firebase';
import { createHousehold } from './household';
import { householdCollection } from './paths';
import { useQuery } from './useQuery';

export type SessionStatus = 'loading' | 'signedOut' | 'needsPerson' | 'ready';

interface SessionValue {
  status: SessionStatus;
  user: User | null;
  household?: WithId<Household>;
  people: WithId<Person>[];
  /** Die Person des angemeldeten Nutzers im aktiven Haushalt. */
  me?: WithId<Person>;
}

const SessionContext = createContext<SessionValue | null>(null);

/** Bei mehreren Haushalten (kurz nach einem Beitritt) gewinnt der mit den meisten Mitgliedern. */
function pickHousehold(households: WithId<Household>[]): WithId<Household> | undefined {
  return households
    .filter((h) => !h.deletedAt)
    .sort((a, b) => b.memberUids.length - a.memberUids.length || a.createdAt.toMillis() - b.createdAt.toMillis())[0];
}

export function SessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [authReady, setAuthReady] = useState(false);

  useEffect(
    () =>
      onAuthStateChanged(auth, (u) => {
        setUser(u);
        setAuthReady(true);
      }),
    [],
  );

  const uid = user?.uid;
  const households = useQuery(
    `households:${uid}`,
    () => (uid ? query(collection(db, 'households'), where('memberUids', 'array-contains', uid)) : null),
    Household,
  );
  const household = pickHousehold(households.data);

  // Erster Login: Erst wenn der Server bestätigt, dass es keinen Haushalt gibt, wird einer angelegt.
  // (Ein leerer Cache-Snapshot heißt nur „noch nichts geladen“.)
  const creating = useRef<string | null>(null);
  useEffect(() => {
    if (!user || !households.loaded || households.fromCache || household) return;
    if (creating.current === user.uid) return;
    creating.current = user.uid;
    createHousehold(user.uid, user.displayName?.split(' ')[0] || 'Ich');
  }, [user, households.loaded, households.fromCache, household]);

  const hid = household?.id;
  const people = useQuery(`people:${hid}`, () => (hid ? householdCollection(hid, 'people') : null), Person);
  const me = people.data.find((p) => p.uid === uid);

  let status: SessionStatus;
  if (!authReady) status = 'loading';
  else if (!user) status = 'signedOut';
  else if (!household || !people.loaded) status = 'loading';
  else if (me) status = 'ready';
  // Person fehlt erst dann wirklich, wenn der Server das bestätigt hat.
  else status = people.fromCache ? 'loading' : 'needsPerson';

  const value = useMemo(
    () => ({ status, user, household, people: people.data, me }),
    [status, user, household, people.data, me],
  );
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): SessionValue {
  const value = useContext(SessionContext);
  if (!value) throw new Error('useSession außerhalb von SessionProvider');
  return value;
}

interface ReadySession {
  user: User;
  household: WithId<Household>;
  me: WithId<Person>;
  people: WithId<Person>[];
}

/**
 * Für Screens, die nur im Status `ready` erreichbar sind. Während eines Wechsels (z. B. Beitritt
 * zu einem anderen Haushalt) kann ein Screen noch einmal rendern, bevor die Routen-Guards ihn
 * entfernen – dann gilt der letzte vollständige Stand.
 */
export function useReadySession(): ReadySession {
  const { user, household, me, people } = useSession();
  const [last, setLast] = useState<ReadySession | null>(null);
  const current = useMemo(
    () => (user && household && me ? { user, household, me, people } : null),
    [user, household, me, people],
  );
  // Abgeleiteter State: beim Rendern aktualisieren statt in einem Effect.
  if (current && current !== last) setLast(current);
  const value = current ?? last;
  if (!value) throw new Error('Session ist nicht bereit');
  return value;
}
