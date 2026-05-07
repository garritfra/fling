import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/data/household.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:fling/layout/drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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

    final HouseholdModel? household = ref.watch(currentHouseholdProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(household?.name ?? AppLocalizations.of(context)!.home),
      ),
      drawer: const FlingDrawer(),
      body: Row(
        children: [
          if (household == null)
            buildCreateHouseholdButton()
          else
            buildListsButton(),
        ],
      ),
    );
  }
}
