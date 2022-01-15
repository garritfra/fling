import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fling/model/shopping_item.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';

class TodoListModel extends ChangeNotifier {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final storage = new LocalStorage("fling.json");

  Future<String> get household async {
    await storage.ready;

    var household = await storage.getItem("household");
    if (household == null) {
      await storage.setItem("household", "liaundgarrit");
    }

    return storage.getItem("household");
  }

  Stream<QuerySnapshot> getItemsInList(String household) {
    return firestore
        .collection("households")
        .doc(household)
        .collection("shoppinglist")
        .orderBy("checked")
        .orderBy("text")
        .snapshots();
  }

  Future<CollectionReference> get shoppingList async {
    return firestore
        .collection("households")
        .doc(await household)
        .collection("shoppinglist");
  }

  void addItem(String text) async {
    Item item =
        new Item(checked: false, id: text.hashCode.toString(), text: text);

    var collection = await shoppingList;

    var ref = await collection.add(item.toMap());
    item.id = ref.id;
    collection.doc(item.id).set(item.toMap());
  }

  void toggleItem(Item item) async {
    item.checked = !item.checked;
    await (await shoppingList).doc(item.id).update(item.toMap());
  }

  void deleteItem(Item item) async {
    var ref = (await shoppingList).doc(item.id);
    await ref.delete();
  }

  void deleteChecked() async {
    WriteBatch batch = firestore.batch();
    await (await shoppingList).where("checked", isEqualTo: true).get().then(
        (values) => values.docs
            .forEach((snapshot) => batch.delete(snapshot.reference)));

    await batch.commit();
  }
}
