import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/data/list_item.dart';

class ListPageArguments {
  final FlingListModel list;

  ListPageArguments(this.list);
}

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final newItemController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as ListPageArguments;

    FlingListModel list = args.list;

    Widget _buildDeleteButton() {
      return IconButton(
          icon: const Icon(Icons.delete),
          color: Colors.red,
          onPressed: () => list.deleteChecked());
    }

    Widget _buildItemTextField() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        // TODO: use subscribed model in state
        child: TextField(
          controller: newItemController,
          onSubmitted: (value) {
            list.addItem(value);
            newItemController.clear();
          },
          decoration: const InputDecoration(
              hintText: "Nudeln",
              border: OutlineInputBorder(),
              labelText: "Item hinzufügen"),
        ),
      );
    }

    Widget _buildListItem(ListItem item) {
      var textController = TextEditingController(text: item.text);
      return Card(
        child: ListTile(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eintrag bearbeiten'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Abbrechen")),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      list.addItem(textController.text);
                      list.deleteItem(item);
                    },
                    child: Text("Fertig")),
              ],
              content: TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(hintText: "Name"),
              ),
            ),
          ),
          leading: Checkbox(
            value: item.checked,
            onChanged: (checked) {
              list.toggleItem(item);
            },
          ),
          title: Text(item.text),
        ),
      );
    }

    Widget _buildItemList() {
      return FutureBuilder(
          future: list.items,
          builder: (context, snapshot) {
            return Expanded(
                child: StreamBuilder(
                    stream: snapshot.data,
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text(
                            "Etwas ist Schiefgegangen: ${snapshot.error}");
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<ListItem> items = snapshot.data!.docs
                          .map<ListItem>((doc) => ListItem.fromMap({
                                "id": doc.id,
                                ...doc.data() as Map<String, dynamic>
                              }))
                          .toList();

                      return ListView.builder(
                          itemCount: items.length,
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          itemBuilder: (BuildContext context, int index) {
                            ListItem item = items.elementAt(index);

                            Widget itemView = _buildListItem(item);

                            if (item.checked) {
                              return Dismissible(
                                  onDismissed: (direction) =>
                                      list.deleteItem(item),
                                  key: Key(item.id),
                                  child: itemView);
                            } else {
                              return Container(
                                  key: Key(item.id), child: itemView);
                            }
                          });
                    }));
          });
    }

    return Consumer<FlingUser?>(
      builder: (BuildContext context, user, Widget? child) {
        return FutureBuilder(
            future: user?.currentHousehold,
            builder: (context, household) {
              return StreamBuilder(
                  stream: household.data,
                  builder: (BuildContext context,
                      AsyncSnapshot<HouseholdModel> household) {
                    return Scaffold(
                      appBar: AppBar(
                        actions: [
                          _buildDeleteButton(),
                        ],
                        title: Text(args.list.name),
                      ),
                      drawer: const FlingDrawer(),
                      body: Center(
                        child: SizedBox(
                          width: 600.0,
                          child: Column(
                            children: [
                              _buildItemList(),
                              _buildItemTextField(),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            });
      },
    );
  }
}
