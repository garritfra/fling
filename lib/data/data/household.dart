import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fling/data/data/list.dart';
import 'package:flutter/foundation.dart';
import 'user.dart';

class HouseholdModel extends ChangeNotifier {
  String? id;
  String name;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  HouseholdModel({this.id, required this.name});

  factory HouseholdModel.fromMap(Map<String, dynamic> data, String? id) {
    return HouseholdModel(id: id, name: data["name"]);
  }

  static Future<HouseholdModel> fromId(String id) async {
    FlingUser? user = await FlingUser.currentUser;
    var snap =
        await FirebaseFirestore.instance.collection("households").doc(id).get();
    return HouseholdModel.fromMap(snap.data() ?? {}, id);
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
    };
  }

  Future<DocumentReference> get ref async {
    FlingUser? user = await FlingUser.currentUser;
    return firestore.collection("households").doc(user?.currentHouseholdId);
  }

  Future<List<FlingListModel>> get lists async {
    var snapshot = await (await ref).collection("lists").get();

    return snapshot.docs
        .map((doc) => FlingListModel.fromMap(doc.data(), doc.id, id!))
        .toList();
  }
}
