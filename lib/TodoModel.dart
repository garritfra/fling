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

  void addItem(String text) {
    Item item =
        new Item(checked: false, id: text.hashCode.toString(), text: text);
    _items.add(item);
    notifyListeners();
  }

  void toggleItem(Item item) {
    item.checked = !item.checked;
    notifyListeners();
  }

  deleteItem(Item item) {
    _items.remove(item);
    notifyListeners();
  }
}
