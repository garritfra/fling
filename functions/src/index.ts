import {
  onDocumentCreated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { beforeUserCreated } from "firebase-functions/v2/identity";
import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

export const cacheJoinHousehold = onDocumentCreated(
  "households/{householdId}/members/{memberId}",
  async (event) => {
    const memberId = event.params.memberId;
    const householdId = event.params.householdId;

    console.log(
      "Caching join event: " +
        `adding member "${memberId}" to household "${householdId}"`
    );

    return db
      .collection("users")
      .doc(memberId)
      .update({
        households: admin.firestore.FieldValue.arrayUnion(householdId),
      });
  }
);

export const cacheLeaveHousehold = onDocumentDeleted(
  "households/{householdId}/members/{memberId}",
  async (event) => {
    const memberId = event.params.memberId;
    const householdId = event.params.householdId;

    console.log(
      "Caching leave event: " +
        `remove member "${memberId}" from household "${householdId}"`
    );

    return db
      .collection("users")
      .doc(memberId)
      .update({
        households: admin.firestore.FieldValue.arrayRemove(householdId),
      });
  }
);

export const inviteToHouseholdByEmail = onCall(async (request) => {
  const uid = request.auth?.uid;
  const householdId = request.data.householdId;
  const invitedEmail = request.data.email;

  console.log("INVITE: User ID:", uid);
  console.log("INVITE: Household ID:", householdId);
  console.log("INVITE: invited Email:", invitedEmail);

  if (!uid) {
    throw new HttpsError(
      "failed-precondition",
      "The function must be called while authenticated."
    );
  }

  const membersRef = db
    .collection("households")
    .doc(householdId)
    .collection("members");

  const existingMemberSnap = await membersRef.doc(uid).get();

  if (!existingMemberSnap.exists) {
    throw new HttpsError(
      "failed-precondition",
      "The user calling this function must be a member of the household."
    );
  }

  const invitedUser = await auth.getUserByEmail(invitedEmail);

  if (!invitedUser.uid) {
    throw new HttpsError(
      "failed-precondition",
      "The invited user does not exist."
    );
  }

  return membersRef.doc(invitedUser.uid).create({});
});

export const setupUser = beforeUserCreated(async (event) => {
  const userId = event.data?.uid;

  if (!userId) {
    logger.error("User ID not found in event data");
    return;
  }

  logger.info(`Setting up user document for ${userId}`);

  await db.collection("users").doc(userId).set({
    households: [],
  });
});

// Note: Firebase Functions v2 doesn't have a beforeUserDeleted blocking function.
// User deletion cleanup should be handled via a callable function that's triggered
// before the client deletes the user, or via Firebase Extensions.
export const deleteUser = onCall(async (request) => {
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  logger.info(`Deleting user document for ${userId}`);

  // Delete user document
  await db.collection("users").doc(userId).delete();

  // Delete the user from Firebase Auth
  await auth.deleteUser(userId);

  return { success: true };
});
