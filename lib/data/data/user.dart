import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'household.dart';

class FlingUser extends ChangeNotifier {
  String uid;
  String? currentHouseholdId;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  FlingUser({required this.uid, this.currentHouseholdId});

  static Future<FlingUser?> get currentUser async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return null;
    }
    var snapshot = await firestore.collection("users").doc(uid).get();
    return FlingUser.fromMap(Map.from(snapshot.data()!), snapshot.id);
  }

  Future<HouseholdModel> get currentHousehold async {
    var snapshot = await firestore.collection("users").doc(uid).get();
    var user = FlingUser.fromMap(Map.from(snapshot.data()!), snapshot.id);

    var householdSnap = await firestore
        .collection("households")
        .doc(user.currentHouseholdId)
        .get();

    return HouseholdModel.fromMap(householdSnap.data()!, householdSnap.id);
  }

  factory FlingUser.fromMap(Map<String, dynamic> data, String uid) {
    return FlingUser(uid: uid, currentHouseholdId: data["current_household"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "current_household": currentHouseholdId,
    };
  }
}
