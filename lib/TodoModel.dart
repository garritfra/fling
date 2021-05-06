import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fling/item.dart';

String listName = "myfirstlist";

class TodoModel extends ChangeNotifier {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get items {
    return firestore
        .collection("lists")
        .doc(listName)
        .collection("items")
        .orderBy("text")
        .snapshots();
  }

  void addItem(String text) async {
    Item item =
        new Item(checked: false, id: text.hashCode.toString(), text: text);

    var collection =
        firestore.collection("lists").doc(listName).collection("items");

    var ref = await collection.add(item.toMap());
    item.id = ref.id;
    collection.doc(item.id).set(item.toMap());
  }

  void toggleItem(Item item) async {
    item.checked = !item.checked;
    await firestore
        .collection("lists")
        .doc(listName)
        .collection("items")
        .doc(item.id)
        .update(item.toMap());
  }

  void deleteItem(Item item) async {
    var ref = firestore
        .collection("lists")
        .doc(listName)
        .collection("items")
        .doc(item.id);
    await ref.delete();
  }
}
