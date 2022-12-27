import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

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
