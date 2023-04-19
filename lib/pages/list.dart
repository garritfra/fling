import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    var l10n = AppLocalizations.of(context)!;

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
            decoration: InputDecoration(
              hintText: l10n.item_hint,
              border: const OutlineInputBorder(),
              labelText: l10n.item_add,
            )),
      );
    }

    Widget _buildListItem(ListItem item) {
      var textController = TextEditingController(text: item.text);
      return Card(
        child: ListTile(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.action_edit_entry),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_cancel)),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      list.addItem(textController.text);
                      list.deleteItem(item);
                    },
                    child: Text(l10n.action_done)),
              ],
              content: TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(hintText: l10n.item_name),
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
                        return Text(l10n.status_error);
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

                      onReorder(int oldIndex, int newIndex) {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final ListItem item = items.removeAt(oldIndex);
                        items.insert(newIndex, item);

                        for (var i = 0; i <= items.length - 1; i++) {
                          items[i].index = i;
                        }

                        list.updateOrder(items);
                      }

                      return ReorderableListView.builder(
                          itemCount: items.length,
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          onReorder: onReorder,
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
