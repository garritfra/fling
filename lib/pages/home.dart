import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/data/data/household.dart';
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Consumer<FlingUser>(
      builder: (BuildContext context, user, Widget? child) {
        return FutureBuilder(
            future: user.currentHousehold,
            builder: (BuildContext context,
                AsyncSnapshot<HouseholdModel> household) {
              return Scaffold(
                appBar: AppBar(
                  // Here we take the value from the HomePage object that was created by
                  // the App.build method, and use it to set our appbar title.
                  title: Text(household.data?.name ?? ""),
                ),
                drawer: const FlingDrawer(),
                body: Center(
                  // Center is a layout widget. It takes a single child and positions it
                  // in the middle of the parent.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Text("TODO: Show overview of home")
                    ],
                  ),
                ),
              );
            });
      },
    );
  }
}
