import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fling/data/data/list.dart';
import 'package:flutter/foundation.dart';
import 'user.dart';

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

  Future<DocumentReference> get ref async {
    FlingUser? user = await FlingUser.currentUser.first;
    return firestore.collection("households").doc(user?.currentHouseholdId);
  }

  Future<HouseholdModel> save() async {
    FlingUser? user = await FlingUser.currentUser.first;
    var ref = await firestore.collection("households").add(toMap());
    await ref.collection("members").doc(user!.uid).set({});
    id = ref.id;
    notifyListeners();
    return this;
  }

  Future<HouseholdModel> leave() async {
    FlingUser? user = await FlingUser.currentUser.first;
    (await ref).collection("members").doc(user?.uid).delete();
    notifyListeners();
    return this;
  }

  Future<void> inviteByEmail(String email) async {
    var callable = functions.httpsCallable('inviteToHouseholdByEmail');
    var user = await FlingUser.currentUser.first;

    await callable({
      "householdId": user?.currentHouseholdId ?? "",
      "email": email,
    });
  }

  Future<Stream<List<FlingListModel>>> get lists async {
    var snapshot = (await ref).collection("lists").snapshots();

    return snapshot.map((snap) => snap.docs
        .map((doc) => FlingListModel.fromMap(doc.data(), doc.id, id!))
        .toList());
  }
}
