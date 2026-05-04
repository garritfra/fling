import type {RequestContext} from "../../core/context/request_context";
import {NotFound} from "../../core/errors/app_error";
import type {Me, PatchMe} from "./schemas";
import * as repo from "./repo";

export async function getMe(ctx: RequestContext): Promise<Me> {
  const me = await repo.readUserDoc(ctx.uid);
  if (!me) throw new NotFound("User document not provisioned yet");
  // Auth-token email always wins over the persisted denormalised value.
  return {...me, email: ctx.email ?? me.email};
}

export async function patchMe(ctx: RequestContext, patch: PatchMe): Promise<Me> {
  await repo.patchUserDoc(ctx.uid, patch);
  return getMe(ctx);
}

export async function createUser(uid: string, email: string | null): Promise<void> {
  await repo.createUserDoc(uid, email);
}

export async function deleteUser(uid: string): Promise<void> {
  // Phase 1: delete the user doc only. Phase 5 upgrades this to cascade.
  await repo.deleteUserDoc(uid);
}
