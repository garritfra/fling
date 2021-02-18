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
                            hintText: "Pasta",
                            border: OutlineInputBorder(),
                            labelText: "Add Item"),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                      key: UniqueKey(),
                      itemCount: model.items.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        Item todo = model.items.elementAt(index);
                        return ItemView(todo);
                      }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
