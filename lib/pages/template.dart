import 'package:fling/data/household.dart';
import 'package:fling/data/template.dart';
import 'package:fling/data/template_item.dart';
import 'package:fling/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TemplatePageArguments {
  final FlingTemplateModel template;

  TemplatePageArguments(this.template);
}

class TemplatePage extends StatefulWidget {
  const TemplatePage({super.key});

  @override
  State<TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<TemplatePage> {
  final newItemController = TextEditingController();
  final newItemFocusNode = FocusNode();

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    newItemController.dispose();
    super.dispose();
  }

  Widget buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1), // Different color from list tags
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: const TextStyle(fontSize: 10, color: Colors.green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as TemplatePageArguments;
    var l10n = AppLocalizations.of(context)!;

    FlingTemplateModel template = args.template;

    Widget buildItemTextField() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        // TODO: use subscribed model in state
        child: TextField(
            controller: newItemController,
            focusNode: newItemFocusNode,
            onSubmitted: (value) {
              template.addItem(value);
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

    Widget buildTemplateItem(TemplateItem item) {
      var textController = TextEditingController(text: item.text);

      void showEditItemDialog() {
        List<String> editedTags = List.from(item.tags);

        var tagController = TextEditingController();

        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(l10n.action_edit_entry),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: textController,
                      autofocus: true,
                      decoration: InputDecoration(hintText: l10n.item_name),
                    ),
                    const SizedBox(height: 16),
                    Text("Tags:",
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: editedTags
                          .map((tag) => Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    editedTags.remove(tag);
                                  });
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tagController,
                            decoration: const InputDecoration(
                              hintText: "Add tag",
                              isDense: true,
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  editedTags.add(value);
                                  tagController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (tagController.text.isNotEmpty) {
                              setState(() {
                                editedTags.add(tagController.text);
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_cancel)),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      template.addItem(textController.text, tags: editedTags);
                      template.deleteItem(item);
                    },
                    child: Text(l10n.action_done)),
              ],
            ),
          ),
        );
      }

      return Card(
        child: ListTile(
          onTap: showEditItemDialog,
          title: Text(item.text),
          subtitle: item.tags.isNotEmpty
              ? Wrap(
                  spacing: 4,
                  children: item.tags
                      .map((tag) => Chip(
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: const EdgeInsets.all(0),
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                )
              : null,
        ),
      );
    }

    Widget buildItemTemplate() {
      return FutureBuilder(
          future: template.items,
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

                      List<TemplateItem> items = snapshot.data!.docs
                          .map<TemplateItem>((doc) => TemplateItem.fromMap({
                                "id": doc.id,
                                ...doc.data() as Map<String, dynamic>
                              }))
                          .toList();

                      return ListView.builder(
                          itemCount: items.length,
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          itemBuilder: (BuildContext context, int index) {
                            TemplateItem item = items.elementAt(index);

                            Widget itemView = buildTemplateItem(item);

                            return Dismissible(
                                onDismissed: (direction) =>
                                    template.deleteItem(item),
                                key: Key(item.id),
                                child: itemView);
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
                        title: Text(args.template.name),
                      ),
                      drawer: const FlingDrawer(),
                      body: Center(
                        child: SizedBox(
                          width: 600.0,
                          child: Column(
                            children: [
                              buildItemTemplate(),
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
