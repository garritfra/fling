import 'package:fling/data/household.dart';
import 'package:fling/data/list.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/features/me/presentation/household_switcher_dialog.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:fling/layout/drawer.dart';
import 'package:fling/pages/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListsPage extends ConsumerStatefulWidget {
  const ListsPage({super.key});

  @override
  ConsumerState<ListsPage> createState() => _ListsPageState();
}

enum HouseholdMenuListAction {
  inviteUser,
  deleteHousehold,
}

class _ListsPageState extends ConsumerState<ListsPage> {
  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;

    void onAddhousehold() {
      Navigator.pushNamed(context, "/household_add");
    }

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
        child: StreamBuilder(
            stream: household.lists,
            builder: (context, snapshot) {
              var lists = snapshot.data ?? [];

              return ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (BuildContext context, int index) {
                    FlingListModel list = lists.elementAt(index);

                    return ListTile(
                      onTap: () => Navigator.pushNamed(context, '/list',
                          arguments: ListPageArguments(list)),
                      onLongPress: () => showListActionsDialog(list),
                      key: Key(list.id ?? list.name),
                      title: Text(list.name),
                    );
                  });
            }),
      );
    }

    Widget buildEmptyHouseholds() {
      return Column(
        children: [
          Text(l10n.household_empty),
          TextButton(
              onPressed: onAddhousehold,
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
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId != null) {
          final household = await HouseholdModel.fromId(householdId);
          await household.inviteByEmail(inviteEmailController.text);
        }
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

    Future<void> showHouseholdSwitcher() => showHouseholdSwitcherDialog(
          context,
          onAddHousehold: onAddhousehold,
        );

    onAddListPressed() {
      TextEditingController textController = TextEditingController();
      NavigatorState navigator = Navigator.of(context);
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
                        final householdId =
                            ref.read(currentHouseholdIdProvider);

                        if (householdId != null) {
                          FlingListModel(
                                  householdId: householdId,
                                  name: textController.text)
                              .save();
                        }
                        navigator.pop();
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

    final HouseholdModel? household =
        ref.watch(currentHouseholdProvider).valueOrNull;

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
                if (household != null) {
                  showDeleteHouseholdDialog(household);
                }
                break;
            }
          },
          itemBuilder: (context) => [
                PopupMenuItem(
                    value: HouseholdMenuListAction.inviteUser,
                    child: Text(l10n.user_invite)),
                PopupMenuItem(
                    value: HouseholdMenuListAction.deleteHousehold,
                    child: Text(l10n.household_leave))
              ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lists),
        actions: household != null
            ? [
                buildSwitchHouseholdAction(),
                buildMoreAction(),
              ]
            : null,
      ),
      floatingActionButton: household != null
          ? FloatingActionButton(
              onPressed: onAddListPressed, child: const Icon(Icons.add))
          : null,
      drawer: const FlingDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (household != null)
              buildLists(household)
            else
              buildEmptyHouseholds(),
          ],
        ),
      ),
    );
  }
}
