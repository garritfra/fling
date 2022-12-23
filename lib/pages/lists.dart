import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/list_item.dart';
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
    var user = Provider.of<FlingUser>(context);

    Widget buildLists(HouseholdModel household) {
      return Expanded(
        child: FutureBuilder<List<FlingListModel>>(
            future: household.lists,
            builder: (context, lists) {
              return ListView.builder(
                  itemCount: lists.data?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    FlingListModel list = lists.data!.elementAt(index);

                    return ListTile(
                      onTap: () => Navigator.pushNamed(context, '/list',
                          arguments: ListPageArguments(list)),
                      key: Key(list.id),
                      title: Text(list.name),
                    );
                  });
            }),
      );
    }

    void showHouseholdSwitcher(List<HouseholdModel> households) {
      void onUpdate(String id) {
        user.setCurrentHouseholdId(id);
        user.notifyListeners();
        Navigator.pop(context);
      }

      showDialog(
          context: context,
          builder: ((context) => AlertDialog(
              title: Text(l10n.households),
              content: Container(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...households.map((h) => ListTile(
                          onTap: () => onUpdate(h.id!),
                          title: Text(h.name),
                          trailing: h.id == user.currentHouseholdId
                              ? const Icon(Icons.check)
                              : null,
                          leading: const Icon(Icons.house),
                        )),
                    ListTile(
                      title: Text(l10n.household_add),
                      leading: Icon(Icons.add),
                    )
                  ],
                ),
              ))));
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
                      var mapFutures = user?.householdIds
                          .map((id) => HouseholdModel.fromId(id))
                          .toList();
                      Future<List<HouseholdModel>> households =
                          Future.wait(mapFutures!);
                      return FutureBuilder<List<HouseholdModel>>(
                          future: households,
                          builder: (context, households) {
                            return IconButton(
                                onPressed: () =>
                                    showHouseholdSwitcher(households.data!),
                                icon: const Icon(Icons.house_outlined));
                          });
                    }

                    return Scaffold(
                      appBar: AppBar(
                        title: Text(household.data?.name ??
                            AppLocalizations.of(context)!.lists),
                        actions: [buildSwitchHouseholdAction()],
                      ),
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
