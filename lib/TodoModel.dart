import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:fling/item.dart';

class TodoModel extends ChangeNotifier {
  final List<Item> _items = [];

  // Expose items as immutable
  UnmodifiableListView<Item> get items => UnmodifiableListView(_items);

  void addItem(String text) {
    Item item = new Item(text);
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
