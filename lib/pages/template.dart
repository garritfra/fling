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
                      template.addItem(textController.text);
                      template.deleteItem(item);
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
          title: Text(item.text),
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
