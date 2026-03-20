import 'package:fling/data/household.dart';
import 'package:fling/data/list.dart';
import 'package:fling/data/list_item.dart';
import 'package:fling/data/template.dart';
import 'package:fling/data/user.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:fling/layout/confirm_dialog.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

enum HouseholdMenuListAction {
  inviteUser,
  deleteHousehold,
}

class _ListsPageState extends State<ListsPage> {
  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;

    void onAddHousehold() {
      Navigator.pushNamed(context, "/household_add");
    }

    Widget buildEmptyHouseholds() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.household_empty),
          TextButton(
              onPressed: onAddHousehold,
              child: Text(l10n.household_create_first))
        ],
      );
    }

    void showDeleteHouseholdDialog(HouseholdModel household) {
      showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              title: Text(l10n.list_delete),
              content: Text(l10n.action_sure),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_cancel)),
                TextButton(
                    onPressed: () {
                      household.leave();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_delete)),
              ],
            )),
      );
    }

    void showInviteDialog() {
      TextEditingController inviteEmailController = TextEditingController();
      NavigatorState navigator = Navigator.of(context);

      Future<void> onInviteUserPressed() async {
        var user = await FlingUser.currentUser.first;
        var household = await (await user?.currentHousehold)?.first;
        household?.inviteByEmail(inviteEmailController.text);
        navigator.pop();
      }

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(l10n.user_invite),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_cancel)),
                  TextButton(
                      onPressed: () {
                        onInviteUserPressed();
                      },
                      child: Text(l10n.action_done)),
                ],
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextField(
                      decoration:
                          InputDecoration(hintText: l10n.user_invite_hint),
                      controller: inviteEmailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ));
    }

    Future<void> showHouseholdSwitcher() async {
      FlingUser? user = await FlingUser.currentUser.first;
      var mapFutures =
          user?.householdIds.map((id) => HouseholdModel.fromId(id)).toList();
      List<HouseholdModel> households = await Future.wait(mapFutures ?? []);

      void onUpdate(String id) {
        user?.setCurrentHouseholdId(id);
        Navigator.pop(context);
      }

      showDialog(
          context: context,
          builder: ((context) => AlertDialog(
              title: Text(l10n.households),
              content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...households.map((h) => ListTile(
                            onTap: () => onUpdate(h.id!),
                            title: Text(h.name),
                            trailing: h.id == user?.currentHouseholdId
                                ? const Icon(Icons.check)
                                : null,
                            leading: const Icon(Icons.house),
                          )),
                      ListTile(
                        onTap: () => onAddHousehold(),
                        title: Text(l10n.household_add),
                        leading: const Icon(Icons.add),
                      )
                    ],
                  )))));
    }

    return StreamBuilder(
      stream: FlingUser.currentUser,
      builder: (BuildContext context, snapshot) {
        var user = snapshot.data;
        return FutureBuilder(
            future: user?.currentHousehold,
            builder: (context, householdSnapshot) {
              return StreamBuilder(
                  stream: householdSnapshot.data,
                  builder: (BuildContext context,
                      AsyncSnapshot<HouseholdModel> householdAsync) {
                    Widget buildSwitchHouseholdAction() {
                      return IconButton(
                          onPressed: showHouseholdSwitcher,
                          icon: const Icon(Icons.swap_horiz));
                    }

                    Widget buildMoreAction() {
                      return PopupMenuButton(
                          onSelected: (selection) {
                            switch (selection) {
                              case HouseholdMenuListAction.inviteUser:
                                showInviteDialog();
                                break;
                              case HouseholdMenuListAction.deleteHousehold:
                                if (householdAsync.data != null) {
                                  showDeleteHouseholdDialog(
                                      householdAsync.data!);
                                }
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: HouseholdMenuListAction.inviteUser,
                                    child: Text(l10n.user_invite)),
                                PopupMenuItem(
                                    value: HouseholdMenuListAction
                                        .deleteHousehold,
                                    child: Text(l10n.household_leave))
                              ]);
                    }

                    if (!householdAsync.hasData) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text(l10n.lists),
                        ),
                        drawer: const FlingDrawer(),
                        body: Center(child: buildEmptyHouseholds()),
                      );
                    }

                    final household = householdAsync.data!;

                    return FutureBuilder(
                        future: household.lists,
                        builder: (context, listsStreamSnapshot) {
                          return StreamBuilder(
                              stream: listsStreamSnapshot.data,
                              builder: (context,
                                  AsyncSnapshot<List<FlingListModel>>
                                      listsAsync) {
                                final lists = listsAsync.data ?? [];

                                void onAddListPressed() {
                                  TextEditingController textController =
                                      TextEditingController();
                                  NavigatorState navigator =
                                      Navigator.of(context);
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: Text(l10n.list_create),
                                            actions: [
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(l10n
                                                      .action_cancel)),
                                              TextButton(
                                                  onPressed: () async {
                                                    FlingUser? user =
                                                        await FlingUser
                                                            .currentUser.first;
                                                    String? householdId =
                                                        user
                                                            ?.currentHouseholdId;
                                                    if (householdId != null) {
                                                      FlingListModel(
                                                              householdId:
                                                                  householdId,
                                                              name: textController
                                                                  .text)
                                                          .save();
                                                    }
                                                    navigator.pop();
                                                  },
                                                  child:
                                                      Text(l10n.action_done)),
                                            ],
                                            content: TextField(
                                              controller: textController,
                                              autofocus: true,
                                              decoration: InputDecoration(
                                                  hintText: l10n.item_name),
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                            ),
                                          ));
                                }

                                return _TabListsView(
                                  lists: lists,
                                  appBarActions: [
                                    IconButton(
                                      onPressed: onAddListPressed,
                                      icon: const Icon(Icons.add),
                                      tooltip: l10n.list_create,
                                    ),
                                    buildSwitchHouseholdAction(),
                                    buildMoreAction(),
                                  ],
                                  appBarTitle: Text(l10n.lists),
                                );
                              });
                        });
                  });
            });
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab view for lists
// ---------------------------------------------------------------------------

class _TabListsView extends StatefulWidget {
  final List<FlingListModel> lists;
  final List<Widget> appBarActions;
  final Widget appBarTitle;

  const _TabListsView({
    required this.lists,
    required this.appBarActions,
    required this.appBarTitle,
  });

  @override
  State<_TabListsView> createState() => _TabListsViewState();
}

class _TabListsViewState extends State<_TabListsView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.lists.length, vsync: this);
  }

  @override
  void didUpdateWidget(_TabListsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lists.length != widget.lists.length) {
      final previousIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: widget.lists.length,
        vsync: this,
        initialIndex: widget.lists.isEmpty
            ? 0
            : previousIndex.clamp(0, widget.lists.length - 1),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDeleteListDialog(BuildContext context, FlingListModel list) {
    var l10n = AppLocalizations.of(context)!;
    showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              title: Text(l10n.list_delete),
              content: Text(l10n.action_sure),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_cancel)),
                TextButton(
                    onPressed: () {
                      list.delete();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_delete)),
              ],
            )));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lists.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: widget.appBarTitle,
          actions: widget.appBarActions,
        ),
        drawer: const FlingDrawer(),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: widget.appBarTitle,
        actions: widget.appBarActions,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: widget.lists.map((list) {
            return GestureDetector(
              onLongPress: () => _showDeleteListDialog(context, list),
              child: Tab(text: list.name),
            );
          }).toList(),
        ),
      ),
      drawer: const FlingDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: widget.lists
            .map((list) => _ListItemsView(list: list))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Items view for a single list
// ---------------------------------------------------------------------------

class _ListItemsView extends StatefulWidget {
  final FlingListModel list;

  const _ListItemsView({required this.list});

  @override
  State<_ListItemsView> createState() => _ListItemsViewState();
}

class _ListItemsViewState extends State<_ListItemsView>
    with AutomaticKeepAliveClientMixin {
  final _newItemController = TextEditingController();
  final _newItemFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _newItemController.dispose();
    _newItemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var l10n = AppLocalizations.of(context)!;
    final list = widget.list;

    Widget buildListItem(ListItem item) {
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
                                deleteIcon:
                                    const Icon(Icons.close, size: 18),
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
                      list.addItem(textController.text, tags: editedTags);
                      list.deleteItem(item);
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
          leading: Checkbox(
            value: item.checked,
            onChanged: (checked) {
              list.toggleItem(item);
            },
          ),
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

    Future<void> showListTemplatesDialog() async {
      FlingUser? user = await FlingUser.currentUser.first;
      HouseholdModel? household =
          await (await user?.currentHousehold)?.first;
      List<FlingTemplateModel> templates =
          await ((await household?.templates)?.first) ?? [];
      templates.sort((a, b) => a.name.compareTo(b.name));

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

    Widget buildItemList() {
      return Expanded(
        child: FutureBuilder(
            future: list.items,
            builder: (context, snapshot) {
              return StreamBuilder(
                  stream: snapshot.data,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(l10n.status_error);
                    }

                    if (!snapshot.hasData) {
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 4.0),
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
                  });
            }),
      );
    }

    Widget buildItemTextField() {
      return Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        child: TextField(
            controller: _newItemController,
            focusNode: _newItemFocusNode,
            onSubmitted: (value) {
              list.addItem(value);
              _newItemController.clear();
              _newItemFocusNode.requestFocus();
            },
            decoration: InputDecoration(
              hintText: l10n.item_hint,
              border: const OutlineInputBorder(),
              labelText: l10n.item_add,
            )),
      );
    }

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 600.0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      onPressed: showListTemplatesDialog,
                      tooltip: l10n.templates,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      color: Colors.red,
                      onPressed: () => showConfirmDialog(
                          context: context,
                          yesText: l10n.action_delete_checked,
                          yesAction: () {
                            Navigator.of(context).pop();
                            list.deleteChecked();
                          }),
                    ),
                  ],
                ),
              ),
              buildItemList(),
              buildItemTextField(),
            ],
          ),
        ),
      ),
    );
  }
}
