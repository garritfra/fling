import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'list_item.dart';

class FlingListModel extends ChangeNotifier {
  String id;
  String householdId;
  String name;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  FlingListModel(
      {required this.id, required this.householdId, required this.name});

  factory FlingListModel.fromMap(
      Map<String, dynamic> data, String id, String householdId) {
    return FlingListModel(id: id, name: data["name"], householdId: householdId);
  }

  Future<Stream<QuerySnapshot<Object?>>> get items async {
    return ref
        .collection("items")
        .orderBy("checked")
        .orderBy("text")
        .snapshots();
  }

  DocumentReference get ref {
    return firestore
        .collection("households")
        .doc(householdId)
        .collection("lists")
        .doc(id);
  }

  void addItem(String text) async {
    ListItem item =
        ListItem(checked: false, id: text.hashCode.toString(), text: text);

    var items = ref.collection("items");

    var itemRef = await items.add(item.toMap());
    item.id = itemRef.id;
    items.doc(item.id).set(item.toMap());
  }

  void toggleItem(ListItem item) async {
    item.checked = !item.checked;
    await ref.collection("items").doc(item.id).update(item.toMap());
  }

  void deleteItem(ListItem item) async {
    var itemRef = ref.collection("items").doc(item.id);
    await itemRef.delete();
  }

  void deleteChecked() async {
    WriteBatch batch = firestore.batch();
    await ref.collection("items").where("checked", isEqualTo: true).get().then(
        (values) => values.docs
            .forEach((snapshot) => batch.delete(snapshot.reference)));

    await batch.commit();
  }
}
