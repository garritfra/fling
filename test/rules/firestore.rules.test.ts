import fs from 'node:fs';
import path from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayRemove,
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

let env: RulesTestEnvironment;

const inHours = (h: number) => Timestamp.fromMillis(Date.now() + h * 3600_000);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-fling',
    firestore: { rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8') },
  });
});

afterAll(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'households/h1'), {
      name: 'Garrit & Lia',
      memberUids: ['garrit'],
      activeModules: ['shopping'],
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'households/h1/shoppingItems/i1'), { ingredientId: 'milk' });
    await setDoc(doc(db, 'invites/VALID1'), { householdId: 'h1', createdBy: 'garrit', expiresAt: inHours(4) });
    await setDoc(doc(db, 'invites/OLD111'), { householdId: 'h1', createdBy: 'garrit', expiresAt: inHours(-1) });
    await setDoc(doc(db, 'invites/USED11'), {
      householdId: 'h1',
      createdBy: 'garrit',
      expiresAt: inHours(4),
      usedAt: Timestamp.now(),
    });
  });
});

const as = (uid: string) => env.authenticatedContext(uid).firestore();

function join(uid: string, code: string, hid = 'h1') {
  const db = as(uid);
  const batch = writeBatch(db);
  batch.update(doc(db, `households/${hid}`), { memberUids: arrayUnion(uid), inviteCode: code });
  batch.update(doc(db, `invites/${code}`), { usedAt: Timestamp.now() });
  return batch.commit();
}

describe('Haushalt', () => {
  it('Mitglieder lesen und schreiben alles unter dem Haushalt', async () => {
    await assertSucceeds(getDoc(doc(as('garrit'), 'households/h1/shoppingItems/i1')));
    await assertSucceeds(setDoc(doc(as('garrit'), 'households/h1/shoppingItems/i2'), { ingredientId: 'x' }));
  });

  it('Nicht-Mitglieder haben keinen Zugriff', async () => {
    await assertFails(getDoc(doc(as('mallory'), 'households/h1')));
    await assertFails(getDoc(doc(as('mallory'), 'households/h1/shoppingItems/i1')));
    await assertFails(setDoc(doc(as('mallory'), 'households/h1/shoppingItems/i2'), { ingredientId: 'x' }));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'households/h1')));
  });

  it('eigene Haushalte lassen sich per array-contains abfragen', async () => {
    const db = as('garrit');
    await assertSucceeds(getDocs(query(collection(db, 'households'), where('memberUids', 'array-contains', 'garrit'))));
    await assertFails(getDocs(collection(db, 'households')));
  });

  it('neuer Haushalt nur mit sich selbst als Mitglied', async () => {
    const base = { name: 'Neu', activeModules: ['shopping'], createdAt: Timestamp.now() };
    await assertSucceeds(setDoc(doc(as('lia'), 'households/h2'), { ...base, memberUids: ['lia'] }));
    await assertFails(setDoc(doc(as('lia'), 'households/h3'), { ...base, memberUids: ['lia', 'garrit'] }));
  });

  it('Mitglieder können umbenennen und verlassen, aber niemanden ohne Einladung hinzufügen', async () => {
    const db = as('garrit');
    await assertSucceeds(updateDoc(doc(db, 'households/h1'), { name: 'Zuhause' }));
    await assertFails(updateDoc(doc(db, 'households/h1'), { memberUids: arrayUnion('mallory') }));
    await assertSucceeds(updateDoc(doc(db, 'households/h1'), { memberUids: arrayRemove('garrit'), deletedAt: Timestamp.now() }));
  });
});

describe('Einladung', () => {
  it('Beitritt mit gültigem Code', async () => {
    await assertSucceeds(join('lia', 'VALID1'));
    await assertSucceeds(getDoc(doc(as('lia'), 'households/h1/shoppingItems/i1')));
  });

  it('ein Code ist nur einmal verwendbar', async () => {
    await assertSucceeds(join('lia', 'VALID1'));
    await assertFails(join('mallory', 'VALID1'));
  });

  it('abgelaufene, benutzte und unbekannte Codes werden abgelehnt', async () => {
    await assertFails(join('lia', 'OLD111'));
    await assertFails(join('lia', 'USED11'));
    await assertFails(join('lia', 'NOPE11'));
  });

  it('Code muss zum Haushalt passen', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'households/other'), {
        name: 'Fremd',
        memberUids: ['someone'],
        activeModules: [],
        createdAt: Timestamp.now(),
      });
    });
    await assertFails(join('lia', 'VALID1', 'other'));
  });

  it('beim Beitritt darf nur die eigene uid hinzukommen', async () => {
    const db = as('lia');
    const batch = writeBatch(db);
    batch.update(doc(db, 'households/h1'), { memberUids: arrayUnion('lia', 'mallory'), inviteCode: 'VALID1' });
    batch.update(doc(db, 'invites/VALID1'), { usedAt: Timestamp.now() });
    await assertFails(batch.commit());

    await assertFails(updateDoc(doc(db, 'households/h1'), { memberUids: arrayUnion('lia'), inviteCode: 'VALID1', name: 'Meins' }));
  });

  it('Einladungen erstellen nur Mitglieder, mit kurzer Laufzeit', async () => {
    const invite = { householdId: 'h1', createdBy: 'garrit', expiresAt: inHours(4) };
    await assertSucceeds(setDoc(doc(as('garrit'), 'invites/NEW111'), invite));
    await assertFails(setDoc(doc(as('garrit'), 'invites/NEW222'), { ...invite, expiresAt: inHours(48) }));
    await assertFails(setDoc(doc(as('mallory'), 'invites/NEW333'), { ...invite, createdBy: 'mallory' }));
  });

  it('Einladungen lassen sich per Code abrufen, aber nicht auflisten', async () => {
    await assertSucceeds(getDoc(doc(as('lia'), 'invites/VALID1')));
    await assertFails(getDocs(collection(as('lia'), 'invites')));
  });

  it('Code kann nicht ohne Beitritt als benutzt markiert werden', async () => {
    await assertFails(updateDoc(doc(as('mallory'), 'invites/VALID1'), { usedAt: Timestamp.now() }));
  });
});
