import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fling/feature_manager.dart';
import 'package:fling/model/shopping_item.dart';
import 'package:fling/model/shopping_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShoppingList extends StatefulWidget {
  ShoppingList({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  final newTodoController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    newTodoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TodoListModel model = context.watch<TodoListModel>();

    Widget _buildDeleteButton() {
      return IconButton(
          icon: Icon(Icons.delete),
          color: Colors.red,
          onPressed: () => model.deleteChecked());
    }

    Widget _buildPreferencesButton() {
      return IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => {Navigator.pushNamed(context, '/settings')});
    }

    Widget _buildAppBar() {
      return AppBar(
        title: Text(widget.title),
        actions: [
          _buildDeleteButton(),
          if (FeatureManager.settings.isEnabled) _buildPreferencesButton()
        ],
      );
    }

    Widget _buildItemTextField() {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        // TODO: use subscribed model in state
        child: Consumer<TodoListModel>(
          builder: (context, model, child) {
            return TextField(
              controller: newTodoController,
              onSubmitted: (value) {
                model.addItem(value);
                newTodoController.clear();
              },
              decoration: InputDecoration(
                  hintText: "Nudeln",
                  border: OutlineInputBorder(),
                  labelText: "Item hinzufügen"),
            );
          },
        ),
      );
    }

    Widget _buildItemList() {
      return FutureBuilder(
          future: model.household,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            String listName = snapshot.data;
            return Expanded(
                child: StreamBuilder(
                    stream: model.getItemsInList(listName),
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text(
                            "Etwas ist Schiefgegangen: ${snapshot.error}");
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      List<Item> items = snapshot.data.docs
                          .map<Item>((QueryDocumentSnapshot doc) =>
                              Item.fromMap({"id": doc.id, ...doc.data()}))
                          .toList();

                      return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, int index) {
                            Item item = items.elementAt(index);
                            return Dismissible(
                                onDismissed: (direction) =>
                                    model.deleteItem(item),
                                key: Key(item.id),
                                child: ItemView(item));
                          });
                    }));
          });
    }

    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: SizedBox(
            width: 600.0,
            child: Column(
              children: [_buildItemTextField(), _buildItemList()],
            ),
          ),
        ),
      ),
    );
  }
}
