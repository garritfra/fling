import 'package:fling/data/household.dart';
import 'package:fling/data/list.dart';
import 'package:fling/data/list_item.dart';
import 'package:fling/data/template.dart';
import 'package:fling/data/user.dart';
import 'package:fling/layout/confirm_dialog.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final newItemFocusNode = FocusNode();

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

    Widget buildDeleteButton() {
      return IconButton(
          icon: const Icon(Icons.delete_sweep),
          color: Colors.red,
          onPressed: () => showConfirmDialog(
              context: context,
              yesText: l10n.action_delete_checked,
              yesAction: () {
                Navigator.of(context).pop();
                list.deleteChecked();
              }));
    }

    Future<void> showListTemplatesDialog() async {
      FlingUser? user = await FlingUser.currentUser.first;
      HouseholdModel? household = await (await user?.currentHousehold)?.first;
      List<FlingTemplateModel> templates =
          await ((await household?.templates)?.first) ?? [];

      Future<void> onAdd(FlingTemplateModel template) async {
        template.applyToList(list);
        Navigator.pop(context);
      }

      showDialog(
          context: context,
          builder: ((context) => AlertDialog(
              title: Text(l10n.templates),
              content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...templates.map((template) => ListTile(
                            onTap: () => onAdd(template),
                            title: Text(template.name),
                          )),
                    ],
                  )))));
    }

    Widget buildAddFromTemplateButton() {
      return IconButton(
          icon: const Icon(Icons.playlist_add),
          onPressed: () => showListTemplatesDialog());
    }

    Widget buildItemTextField() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        // TODO: use subscribed model in state
        child: TextField(
            controller: newItemController,
            focusNode: newItemFocusNode,
            onSubmitted: (value) {
              list.addItem(value);
              newItemController.clear();
              newItemFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              hintText: l10n.item_hint,
              border: const OutlineInputBorder(),
              labelText: l10n.item_add,
            )),
      );
    }

    Widget buildListItem(ListItem item) {
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

    Widget buildItemList() {
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

                      return ListView.builder(
                          itemCount: items.length,
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          itemBuilder: (BuildContext context, int index) {
                            ListItem item = items.elementAt(index);

                            Widget itemView = buildListItem(item);

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
                          buildAddFromTemplateButton(),
                          buildDeleteButton(),
                        ],
                        title: Text(args.list.name),
                      ),
                      drawer: const FlingDrawer(),
                      body: Center(
                        child: SizedBox(
                          width: 600.0,
                          child: Column(
                            children: [
                              buildItemList(),
                              buildItemTextField(),
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
