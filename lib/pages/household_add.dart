import 'package:fling/data/household.dart';
import 'package:fling/data/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddHousehold extends StatefulWidget {
  const AddHousehold({super.key});

  @override
  State<AddHousehold> createState() => _AddHouseholdState();
}

class _AddHouseholdState extends State<AddHousehold> {
  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    Future<void> onCreateHousehold() async {
      var household = await HouseholdModel(name: nameController.text).save();
      var user = await FlingUser.currentUser.first;
      user?.setCurrentHouseholdId(household.id!);

      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.household_add)),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          TextField(
              controller: nameController,
              onSubmitted: (value) => onCreateHousehold(),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.household_name,
              )),
          Container(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onCreateHousehold(),
              child: Text(l10n.household_create),
            ),
          )
        ]),
      ),
    );
  }
}
