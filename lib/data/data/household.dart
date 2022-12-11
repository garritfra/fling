import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user.dart';

class HouseholdModel extends ChangeNotifier {
  String? id;
  String name;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  HouseholdModel({this.id, required this.name});

  Future<HouseholdModel> get currentHousehold async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    var snapshot = await firestore.collection("users").doc(uid).get();
    var user = FlingUser.fromMap(Map.from(snapshot.data()!), snapshot.id);

    var householdSnap = await firestore
        .collection("households")
        .doc(user.currentHouseholdId)
        .get();

    return HouseholdModel.fromMap(householdSnap.data()!, householdSnap.id);
  }

  factory HouseholdModel.fromMap(Map<String, dynamic> data, String? id) {
    return HouseholdModel(id: id, name: data["name"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
    };
  }
}
