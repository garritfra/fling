import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import type {Me} from "./schemas";

function db() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

interface RawUserDoc {
  email?: string;
  display_name?: string;
  household_ids?: string[];
  current_household_id?: string;
  // legacy field names — read for backwards compatibility until Phase 6
  households?: string[];
  current_household?: string;
}

export async function readUserDoc(uid: string): Promise<Me | null> {
  const snap = await db().collection("users").doc(uid).get();
  if (!snap.exists) return null;
  const raw = snap.data() as RawUserDoc;
  return {
    uid,
    email: raw.email ?? null,
    displayName: raw.display_name ?? null,
    householdIds: raw.household_ids ?? raw.households ?? [],
    currentHouseholdId: raw.current_household_id ?? raw.current_household ?? null,
  };
}

export async function patchUserDoc(uid: string, patch: {
  currentHouseholdId?: string;
  displayName?: string;
}): Promise<void> {
  const update: Record<string, unknown> = {
    updated_at: FieldValue.serverTimestamp(),
  };
  if (patch.currentHouseholdId !== undefined) {
    update.current_household_id = patch.currentHouseholdId;
    // Dual-write the legacy field while Flutter clients still read it.
    update.current_household = patch.currentHouseholdId;
  }
  if (patch.displayName !== undefined) {
    update.display_name = patch.displayName;
  }
  await db().collection("users").doc(uid).set(update, {merge: true});
}

export async function createUserDoc(uid: string, email: string | null): Promise<void> {
  await db().collection("users").doc(uid).set({
    email: email ?? null,
    display_name: null,
    household_ids: [],
    current_household_id: null,
    households: [],            // legacy, dual-write
    current_household: null,   // legacy, dual-write
    schema_version: 1,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
    created_by_uid: uid,
  }, {merge: true});
}

export async function deleteUserDoc(uid: string): Promise<void> {
  await db().collection("users").doc(uid).delete();
}
