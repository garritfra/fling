import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'household.dart';

class FlingUser extends ChangeNotifier {
  String uid;
  String? currentHouseholdId;
  List<String> householdIds;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  FlingUser(
      {required this.uid, this.currentHouseholdId, required this.householdIds});

  static Stream<FlingUser?> get currentUser {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    String? uid = FirebaseAuth.instance.currentUser?.uid;
    var snapshots = firestore.collection("users").doc(uid).snapshots();
    return snapshots.asyncMap((snapshot) async {
      if (snapshot.data() == null) {
        await firestore.collection("users").doc(uid).set({});
      }
      return FlingUser.fromMap(Map.from(snapshot.data() ?? {}), snapshot.id);
    });
  }

  DocumentReference<Map<String, dynamic>> get ref {
    return firestore.collection("users").doc(uid);
  }

  Future<Stream<HouseholdModel>> get currentHousehold async {
    var snapshot = await ref.get();
    var user = FlingUser.fromMap(Map.from(snapshot.data()!), snapshot.id);

    return firestore
        .collection("households")
        .doc(user.currentHouseholdId)
        .snapshots()
        .map((snap) => HouseholdModel.fromMap(snap.data()!, snap.id));
  }

  setCurrentHouseholdId(String id) async {
    await ref.update({"current_household": id}).then((value) {
      currentHouseholdId = id;
    });
    notifyListeners();
  }

  deleteAccount() async {
    await FirebaseAuth.instance.currentUser?.delete();
  }

  factory FlingUser.fromMap(Map<String, dynamic> data, String uid) {
    return FlingUser(
        uid: uid,
        currentHouseholdId: data["current_household"],
        householdIds: data["households"] != null
            ? List<String>.from(data["households"])
            : []);
  }
}
