import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:fling/pages/list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  @override
  Widget build(BuildContext context) {
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
                        title: const Text("Listen"),
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
