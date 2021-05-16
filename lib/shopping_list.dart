import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'TodoModel.dart';
import 'item.dart';

class ShoppingList extends StatefulWidget {
  ShoppingList({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  final newTodoController = TextEditingController();
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController(keepScrollOffset: true);
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
    TodoModel model = context.watch<TodoModel>();

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
        actions: [_buildDeleteButton(), _buildPreferencesButton()],
      );
    }

    Widget _buildItemTextField() {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        // TODO: use subscribed model in state
        child: Consumer<TodoModel>(
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
      return Expanded(
          child: StreamBuilder(
              stream: model.items,
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text("Etwas ist Schiefgegangen: ${snapshot.error}");
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
                          onDismissed: (direction) => model.deleteItem(item),
                          key: Key(item.id),
                          child: ItemView(item));
                    });
              }));
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
