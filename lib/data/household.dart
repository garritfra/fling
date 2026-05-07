import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/data/list.dart';
import 'package:fling/data/template.dart';
import 'package:flutter/foundation.dart';

class HouseholdModel extends ChangeNotifier {
  String? id;
  String name;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseFunctions functions = FirebaseFunctions.instance;

  HouseholdModel({this.id, required this.name});

  factory HouseholdModel.fromMap(Map<String, dynamic> data, String? id) {
    return HouseholdModel(id: id, name: data["name"] ?? "");
  }

  static Future<HouseholdModel> fromId(String id) async {
    var snap =
        await FirebaseFirestore.instance.collection("households").doc(id).get();
    var data = snap.data() ?? {};
    if (data != {}) {
      return HouseholdModel.fromMap(data, id);
    }

    return HouseholdModel(name: "");
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
    };
  }

  /// The Firestore document for this household. Synchronous and bound to
  /// the model's own [id]. The "current household" coupling lives at the
  /// page layer via Riverpod's `currentHouseholdIdProvider`.
  DocumentReference get ref =>
      firestore.collection("households").doc(id);

  Future<HouseholdModel> save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final newRef = await firestore.collection("households").add(toMap());
    if (uid != null) {
      await newRef.collection("members").doc(uid).set({});
    }
    id = newRef.id;
    notifyListeners();
    return this;
  }

  Future<HouseholdModel> leave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await ref.collection("members").doc(uid).delete();
    }
    notifyListeners();
    return this;
  }

  Future<void> inviteByEmail(String email) async {
    final callable = functions.httpsCallable('inviteToHouseholdByEmail');
    await callable({
      "householdId": id ?? "",
      "email": email,
    });
  }

  Stream<List<FlingListModel>> get lists {
    return ref.collection("lists").snapshots().map((snap) => snap.docs
        .map((doc) => FlingListModel.fromMap(doc.data(), doc.id, id!))
        .toList());
  }

  Stream<List<FlingTemplateModel>> get templates {
    return ref.collection("templates").snapshots().map((snap) => snap.docs
        .map((doc) => FlingTemplateModel.fromMap(doc.data(), doc.id, id!))
        .toList());
  }
}
