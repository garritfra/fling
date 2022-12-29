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

class _ListsPageState extends State<ListsPage> {
  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    var user = Provider.of<FlingUser?>(context);

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
                            key: Key(list.id ?? list.name),
                            title: Text(list.name),
                          );
                        });
                  });
            }),
      );
    }

    void showHouseholdSwitcher() {
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
                child: StreamBuilder(
                    stream: FlingUser.currentUser,
                    builder: (context, snapshot) {
                      var mapFutures = snapshot.data?.householdIds
                          .map((id) => HouseholdModel.fromId(id))
                          .toList();
                      Future<List<HouseholdModel>> householdsFuture =
                          Future.wait(mapFutures ?? []);
                      return FutureBuilder(
                          future: householdsFuture,
                          builder: (context, snapshot) {
                            return ListView(
                              shrinkWrap: true,
                              children: [
                                ...?snapshot.data?.map((h) => ListTile(
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
                            );
                          });
                    }),
              ))));
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
                      onPressed: () {
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
                ),
              ));
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
                    Widget buildSwitchHouseholdAction() {
                      return IconButton(
                          onPressed: () => showHouseholdSwitcher(),
                          icon: const Icon(Icons.house_outlined));
                    }

                    return Scaffold(
                      appBar: AppBar(
                        title: Text(household.data?.name ??
                            AppLocalizations.of(context)!.lists),
                        actions: [buildSwitchHouseholdAction()],
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
