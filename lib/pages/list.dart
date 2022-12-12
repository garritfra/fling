import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as ListPageArguments;

    return Consumer<FlingUser>(
      builder: (BuildContext context, user, Widget? child) {
        return FutureBuilder(
            future: user.currentHousehold,
            builder: (BuildContext context,
                AsyncSnapshot<HouseholdModel> household) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(args.list.name),
                ),
                drawer: const FlingDrawer(),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [Text("LIST ITEMS GO HERE")],
                  ),
                ),
              );
            });
      },
    );
  }
}
