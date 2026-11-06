import { onSnapshot, type Query } from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import type { z } from 'zod';
import type { WithId } from '../../schema';

export interface QueryState<T> {
  data: WithId<T>[];
  /** Mindestens ein Snapshot ist da (ggf. aus dem Cache). */
  loaded: boolean;
  /** Letzter Snapshot kam aus dem lokalen Cache, nicht vom Server. */
  fromCache: boolean;
}

const initial: QueryState<never> = { data: [], loaded: false, fromCache: true };

function parse<T>(schema: z.ZodType<T>, id: string, raw: unknown): WithId<T> | undefined {
  const result = schema.safeParse(raw);
  if (!result.success) {
    console.warn(`Ungültiges Dokument ${id}`, result.error.issues);
    return undefined;
  }
  return { ...result.data, id };
}

/**
 * Realtime-Listener auf eine Abfrage. `key` muss sich ändern, wenn sich die Abfrage ändert
 * (Query-Objekte sind bei jedem Render neu). `makeQuery` darf `null` liefern (noch nichts zu laden).
 * Ungültige Dokumente werden übersprungen und protokolliert.
 */
export function useQuery<T>(key: string, makeQuery: () => Query | null, schema: z.ZodType<T>): QueryState<T> {
  const [state, setState] = useState<{ key: string } & QueryState<T>>({ key, ...initial });

  useEffect(() => {
    const q = makeQuery();
    if (!q) return;
    return onSnapshot(
      q,
      { includeMetadataChanges: true },
      (snapshot) => {
        const data = snapshot.docs
          .map((d) => parse(schema, d.id, d.data()))
          .filter((d): d is WithId<T> => d !== undefined);
        setState({ key, data, loaded: true, fromCache: snapshot.metadata.fromCache });
      },
      (error) => console.warn(`Listener ${key} fehlgeschlagen`, error),
    );
    // makeQuery und schema sind über key abgedeckt.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  // Ergebnisse einer früheren Abfrage (anderer key) nie anzeigen.
  return state.key === key ? state : initial;
}
