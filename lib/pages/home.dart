import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/data/data/household.dart';
import 'package:fling/data/data/list.dart';
import 'package:fling/data/data/user.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((user) => {
          if (user == null) {Navigator.popAndPushNamed(context, "/login")}
        });

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
          builder: (context, household) => StreamBuilder(
              stream: household.data,
              builder: (BuildContext context,
                  AsyncSnapshot<HouseholdModel> household) {
                return Scaffold(
                  appBar: AppBar(
                    // Here we take the value from the HomePage object that was created by
                    // the App.build method, and use it to set our appbar title.
                    title: Text(household.data?.name ?? ""),
                  ),
                  drawer: const FlingDrawer(),
                  body: Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () {
                              // TODO: Possible memory leak. Proper navigation concept needed
                              Navigator.pushNamed(context, '/lists');
                            },
                            child: SizedBox(
                              height: 100,
                              width: 300,
                              child: Center(
                                  child: Text(
                                'Listen',
                                style: Theme.of(context).textTheme.displaySmall,
                              )),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }
}
