import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fling/TodoModel.dart';
import 'package:provider/provider.dart';

class Item {
  String text;
  bool checked;

  Item(String text) {
    this.checked = false;
    this.text = text;
  }
}

class ItemView extends StatefulWidget {
  final Item todo;
  ItemView(this.todo);

  @override
  _ItemViewState createState() => _ItemViewState(todo);
}

class _ItemViewState extends State<ItemView> {
  Item todo;
  _ItemViewState(Item todo) {
    this.todo = todo;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: UniqueKey(),
      child: Consumer<TodoModel>(
        builder: (context, model, child) {
          return ListTile(
            leading: Checkbox(
              value: todo.checked,
              onChanged: (bool value) {
                model.toggleItem(todo);
              },
            ),
            title: Text(widget.todo.text),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => model.deleteItem(todo),
            ),
          );
        },
      ),
    );
  }
}
