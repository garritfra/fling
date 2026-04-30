import {z} from "@hono/zod-openapi";

export const MeSchema = z.object({
  uid: z.string(),
  email: z.string().email().nullable(),
  displayName: z.string().nullable(),
  householdIds: z.array(z.string()),
  currentHouseholdId: z.string().nullable(),
}).openapi("Me");

export const PatchMeSchema = z.object({
  currentHouseholdId: z.string().min(1).max(128).optional(),
  displayName: z.string().min(1).max(128).optional(),
}).strict().openapi("PatchMe");

export type Me = z.infer<typeof MeSchema>;
export type PatchMe = z.infer<typeof PatchMeSchema>;
