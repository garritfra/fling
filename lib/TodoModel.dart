import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fling/item.dart';

class TodoModel extends ChangeNotifier {
  List<Item> _items = [];
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Expose items as immutable
  UnmodifiableListView<Item> get items => UnmodifiableListView(_items);

  TodoModel() {
    firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .snapshots()
        .listen((event) => init());
    init();
  }

  Future init() async {
    var snapshot = await firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .get();
    List<Item> fetchedItems = [];
    for (var entry in snapshot.docs) {
      var data = entry.data();
      Item item =
          Item(id: entry.id, checked: data["checked"], text: data["text"]);
      fetchedItems.add(item);
    }

    _items = fetchedItems;

    notifyListeners();
  }

  void addItem(String text) async {
    Item item =
        new Item(checked: false, id: text.hashCode.toString(), text: text);

    var ref = await firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .add(item.toMap());
    item.id = ref.id;
    notifyListeners();
  }

  void toggleItem(Item item) async {
    item.checked = !item.checked;
    await firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .doc(item.id)
        .set(item.toMap());
    notifyListeners();
  }

  deleteItem(Item item) async {
    await firestore
        .collection("lists")
        .doc("myfirstlist")
        .collection("items")
        .doc(item.id)
        .delete();
    notifyListeners();
  }
}
