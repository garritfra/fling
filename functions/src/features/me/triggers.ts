import * as functionsV1 from "firebase-functions/v1";
import {createUser, deleteUser} from "./service";

export interface AuthUserLike {
  uid: string;
  email?: string | null;
}

export async function handleUserCreated(user: AuthUserLike): Promise<void> {
  await createUser(user.uid, user.email ?? null);
}

export async function handleUserDeleted(user: AuthUserLike): Promise<void> {
  await deleteUser(user.uid);
}

export const onUserCreated = functionsV1.auth.user().onCreate((u) =>
  handleUserCreated({uid: u.uid, email: u.email ?? null}),
);

export const onUserDeleted = functionsV1.auth.user().onDelete((u) =>
  handleUserDeleted({uid: u.uid, email: u.email ?? null}),
);
