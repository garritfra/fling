import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fling/data/list.dart';
import 'package:flutter/foundation.dart';

import 'template_item.dart';

class FlingTemplateModel extends ChangeNotifier {
  String? id;
  String householdId;
  String name;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  FlingTemplateModel({required this.householdId, required this.name, this.id});

  factory FlingTemplateModel.fromMap(
      Map<String, dynamic> data, String id, String householdId) {
    return FlingTemplateModel(
        id: id, name: data["name"], householdId: householdId);
  }

  Future<Stream<QuerySnapshot<Object?>>> get items async {
    return ref.collection("items").orderBy("text").snapshots();
  }

  DocumentReference get ref {
    return firestore
        .collection("households")
        .doc(householdId)
        .collection("templates")
        .doc(id);
  }

  void addItem(String text) async {
    TemplateItem item = TemplateItem(id: text.hashCode.toString(), text: text);

    var items = ref.collection("items");

    var itemRef = await items.add(item.toMap());
    item.id = itemRef.id;
    items.doc(item.id).set(item.toMap());
  }

  void deleteItem(TemplateItem item) async {
    var itemRef = ref.collection("items").doc(item.id);
    await itemRef.delete();
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
    };
  }

  Future<FlingTemplateModel?> delete() async {
    await ref.delete();
    notifyListeners();
    return this;
  }

  Future<FlingTemplateModel?> save() async {
    var ref = await firestore
        .collection("households")
        .doc(householdId)
        .collection("templates")
        .add(toMap());
    id = ref.id;
    notifyListeners();
    return this;
  }

  Future<void> applyTolist(FlingListModel list) async {
    await for (var snapshot in await items) {
      for (var itemDoc in snapshot.docs) {
        list.addItem(itemDoc.get('text'));
      }
    }
  }
}
