import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

exports.cacheJoinHousehold = functions.firestore
  .document("households/{householdId}/members/{memberId}")
  .onCreate((change, context) => {
    const memberId = context.params.memberId;
    const householdId = context.params.householdId;

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
  });

exports.cacheLeaveHousehold = functions.firestore
  .document("households/{householdId}/members/{memberId}")
  .onDelete((change, context) => {
    const memberId = context.params.memberId;
    const householdId = context.params.householdId;

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
  });

exports.inviteToHouseholdByEmail = functions.https.onCall(
  async (data, context) => {
    const uid = context?.auth?.uid;
    const householdId = data.householdId;
    const invitedEmail = data.email;

    console.log("INVITE: User ID:", uid);
    console.log("INVITE: Household ID:", householdId);
    console.log("INVITE: invited Email:", invitedEmail);

    if (!uid) {
      throw new functions.https.HttpsError(
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
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The user calling this function must be a member of the household."
      );
    }

    const invitedUser = await auth.getUserByEmail(invitedEmail);

    if (!invitedUser.uid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The invited user does not exist."
      );
    }

    return membersRef.doc(invitedUser.uid).create({});
  }
);
