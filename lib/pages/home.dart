import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/data/household.dart';
import 'package:fling/data/user.dart';
import 'package:fling/l10n/app_localizations.dart';
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
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        Navigator.popAndPushNamed(context, "/login");
      }
    });

    Widget buildCreateHouseholdButton() {
      return Expanded(
        child: Card(
          color: const Color.fromARGB(255, 51, 138, 126),
          child: InkWell(
            onTap: () {
              showAboutDialog(context: context);
            },
            child: SizedBox(
              height: 100,
              width: 300,
              child: Center(
                  child: Text(
                AppLocalizations.of(context)!.household_create,
                style: Theme.of(context).textTheme.labelLarge,
              )),
            ),
          ),
        ),
      );
    }

    Widget buildListsButton() {
      return Expanded(
        child: Card(
          color: const Color.fromARGB(255, 51, 138, 126),
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
                AppLocalizations.of(context)!.lists,
                style: Theme.of(context).textTheme.labelLarge,
              )),
            ),
          ),
        ),
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
                    title: Text(household.data?.name ??
                        AppLocalizations.of(context)!.home),
                  ),
                  drawer: const FlingDrawer(),
                  body: Row(
                    children: [
                      if (household.data == null)
                        buildCreateHouseholdButton()
                      else
                        buildListsButton(),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }
}
