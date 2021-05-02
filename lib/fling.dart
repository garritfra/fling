import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'TodoModel.dart';
import 'item.dart';

class FlingApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TodoPage(title: 'Fling'),
    );
  }
}

class TodoPage extends StatefulWidget {
  TodoPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final newTodoController = TextEditingController();

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

    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: SizedBox(
            width: 600.0,
            child: Column(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
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
                ),
                Expanded(
                    child: StreamBuilder(
                        stream: model.items,
                        builder: (context, snapshot) {
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Text(
                                "Etwas ist Schiefgegangen: ${snapshot.error}");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          List<Item> items = snapshot.data.docs
                              .map<Item>((QueryDocumentSnapshot doc) =>
                                  Item.fromMap({"id": doc.id, ...doc.data()}))
                              .toList();

                          items.sort((Item i1, Item i2) => i1.text
                              .toLowerCase()
                              .compareTo(i2.text.toLowerCase()));

                          return ListView(
                            key: UniqueKey(),
                            children: items.map((Item item) {
                              return ItemView(item);
                            }).toList(),
                          );
                        })),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
