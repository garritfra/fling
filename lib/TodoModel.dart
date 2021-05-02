import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fling/item.dart';

class TodoModel extends ChangeNotifier {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get items {
    return firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .snapshots();
  }

  void addItem(String text) async {
    Item item =
        new Item(checked: false, id: text.hashCode.toString(), text: text);

    var collection = await firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items");

    var ref = await collection.add(item.toMap());
    item.id = ref.id;
    collection.doc(item.id).set(item.toMap());
  }

  void toggleItem(Item item) async {
    item.checked = !item.checked;
    await firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .doc(item.id)
        .update(item.toMap());
  }

  deleteItem(Item item) async {
    var ref = firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .doc(item.id);
    await ref.delete();
  }
}
