import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import type {Migration} from "./runner";

const BATCH = 400;

const migration: Migration = {
  id: "001-user-shape",
  up: async () => {
    if (getApps().length === 0) initializeApp();
    const db = getFirestore();
    const auth = getAuth();
    let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    while (true) {
      let q = db.collection("users").orderBy("__name__").limit(BATCH);
      if (last) q = q.startAfter(last);
      const snap = await q.get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const doc of snap.docs) {
        const data = doc.data();
        if (data.schema_version === 1) continue; // idempotent
        let email: string | null = data.email ?? null;
        if (!email) {
          try {
            email = (await auth.getUser(doc.id)).email ?? null;
          } catch {
            email = null;
          }
        }
        batch.set(doc.ref, {
          email,
          display_name: data.display_name ?? null,
          household_ids: data.household_ids ?? data.households ?? [],
          current_household_id:
            data.current_household_id ?? data.current_household ?? null,
          // Preserve legacy fields untouched (compaction in Phase 6 drops them).
          households: data.households ?? data.household_ids ?? [],
          current_household:
            data.current_household ?? data.current_household_id ?? null,
          schema_version: 1,
          created_at: data.created_at ?? FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          created_by_uid: data.created_by_uid ?? doc.id,
        }, {merge: true});
      }
      await batch.commit();
      last = snap.docs[snap.docs.length - 1];
      if (snap.size < BATCH) break;
    }
  },
};

export default migration;
