import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fling/item.dart';
import 'package:localstorage/localstorage.dart';

String listName = "myfirstlist";

class TodoModel extends ChangeNotifier {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final storage = new LocalStorage("fling.json");

  Future<String> get listName async {
    await storage.ready;

    return storage.getItem("list");
  }

  Stream<QuerySnapshot> getItemsInList(String list) {
    return firestore
        .collection("lists")
        .doc(list)
        .collection("items")
        .orderBy("text")
        .snapshots();
  }

  void addItem(String text) async {
    Item item =
        new Item(checked: false, id: text.hashCode.toString(), text: text);

    var collection =
        firestore.collection("lists").doc(await listName).collection("items");

    var ref = await collection.add(item.toMap());
    item.id = ref.id;
    collection.doc(item.id).set(item.toMap());
  }

  void toggleItem(Item item) async {
    item.checked = !item.checked;
    await firestore
        .collection("lists")
        .doc(await listName)
        .collection("items")
        .doc(item.id)
        .update(item.toMap());
  }

  void deleteItem(Item item) async {
    var ref = firestore
        .collection("lists")
        .doc(await listName)
        .collection("items")
        .doc(item.id);
    await ref.delete();
  }

  void deleteChecked() async {
    WriteBatch batch = firestore.batch();
    await firestore
        .collection("lists")
        .doc(await listName)
        .collection("items")
        .where("checked", isEqualTo: true)
        .get()
        .then((values) => values.docs
            .forEach((snapshot) => batch.delete(snapshot.reference)));

    await batch.commit();
  }
}
