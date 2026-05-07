import {getApps, initializeApp} from "firebase-admin/app";
import {getFirestore, Timestamp} from "firebase-admin/firestore";

export interface IdempotencyRecord {
  status: number;
  body: string;
  bodyHash: string;
  contentType: string;
}

function db() {
  if (getApps().length === 0) initializeApp();
  return getFirestore();
}

const TTL_MS = 24 * 60 * 60 * 1000;

export function compositeId(uid: string, key: string): string {
  return `${uid}_${key}`;
}

export async function lookup(uid: string, key: string): Promise<IdempotencyRecord | null> {
  const snap = await db().collection("idempotency_keys").doc(compositeId(uid, key)).get();
  if (!snap.exists) return null;
  const d = snap.data()!;
  return {
    status: d.status,
    body: d.body,
    bodyHash: d.body_hash,
    contentType: d.content_type,
  };
}

export async function save(uid: string, key: string, rec: IdempotencyRecord): Promise<void> {
  await db().collection("idempotency_keys").doc(compositeId(uid, key)).set({
    status: rec.status,
    body: rec.body,
    body_hash: rec.bodyHash,
    content_type: rec.contentType,
    expires_at: Timestamp.fromMillis(Date.now() + TTL_MS),
  });
}
