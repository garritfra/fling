import 'dart:ffi';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:fling/pages/list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final functions = FirebaseFunctions.instance;

  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;

    void showListActionsDialog(FlingListModel list) {
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

    Widget buildLists(HouseholdModel household) {
      return Expanded(
        child: FutureBuilder(
            future: household.lists,
            builder: (context, lists) {
              return StreamBuilder(
                  stream: lists.data,
                  builder: (context, snapshot) {
                    return ListView.builder(
                        itemCount: snapshot.data?.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          FlingListModel list = snapshot.data!.elementAt(index);

                          return ListTile(
                            onTap: () => Navigator.pushNamed(context, '/list',
                                arguments: ListPageArguments(list)),
                            onLongPress: () => showListActionsDialog(list),
                            key: Key(list.id ?? list.name),
                            title: Text(list.name),
                          );
                        });
                  });
            }),
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
      TextEditingController textController = TextEditingController();
      String? errorText;

      Future<void> onInviteUserPressed() async {
        var callable = functions.httpsCallable('inviteToHouseholdByEmail');
        var user = await FlingUser.currentUser.first;

        var result = await callable({
          "householdId": user?.currentHouseholdId ?? "",
          "email": textController.text,
        });

        Navigator.of(context).pop();
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
                content: TextField(
                  controller: textController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
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
        user?.notifyListeners();
        Navigator.pop(context);
      }

      void onAddhousehold() {
        Navigator.popAndPushNamed(context, "/household_add");
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
                        onTap: () => onAddhousehold(),
                        title: Text(l10n.household_add),
                        leading: const Icon(Icons.add),
                      )
                    ],
                  )))));
    }

    onAddListPressed() {
      TextEditingController textController = TextEditingController();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(l10n.list_create),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_cancel)),
                  TextButton(
                      onPressed: () async {
                        FlingUser? user = await FlingUser.currentUser.first;
                        String? householdId = user?.currentHouseholdId;

                        if (householdId != null) {
                          FlingListModel(
                                  householdId: householdId,
                                  name: textController.text)
                              .save();
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_done)),
                ],
                content: TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(hintText: l10n.item_name),
                  keyboardType: TextInputType.emailAddress,
                ),
              ));
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
                      AsyncSnapshot<HouseholdModel> household) {
                    Widget buildSwitchHouseholdAction() {
                      return IconButton(
                          onPressed: () => showHouseholdSwitcher(),
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
                                if (household.data != null) {
                                  showDeleteHouseholdDialog(household.data!);
                                }
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: HouseholdMenuListAction.inviteUser,
                                    child: Text(l10n.user_invite)),
                                PopupMenuItem(
                                    value:
                                        HouseholdMenuListAction.deleteHousehold,
                                    child: Text(l10n.household_leave))
                              ]);
                    }

                    return Scaffold(
                      appBar: AppBar(
                        title: Text(household.data?.name ??
                            AppLocalizations.of(context)!.lists),
                        actions: [
                          buildSwitchHouseholdAction(),
                          buildMoreAction(),
                        ],
                      ),
                      floatingActionButton: FloatingActionButton(
                          onPressed: () => onAddListPressed(),
                          child: const Icon(Icons.add)),
                      drawer: const FlingDrawer(),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if (household.hasData) buildLists(household.data!)
                          ],
                        ),
                      ),
                    );
                  });
            });
      },
    );
  }
}
