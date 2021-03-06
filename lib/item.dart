import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fling/TodoModel.dart';
import 'package:provider/provider.dart';

class Item {
  String id;
  String text;
  bool checked;

  Item.withText(String text) {
    // TODO: Will this cause errors?
    this.id = "";
    this.checked = false;
    this.text = text;
  }

  Item({this.id, this.text, this.checked});

  factory Item.fromMap(Map<String, dynamic> data) {
    return Item(id: data["id"], checked: data["checked"], text: data["text"]);
  }

  Map<String, dynamic> toMap() {
    return {
      "checked": checked,
      "text": text,
    };
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
          );
        },
      ),
    );
  }
}
