import 'package:fling/data/household.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddHousehold extends ConsumerStatefulWidget {
  const AddHousehold({super.key});

  @override
  ConsumerState<AddHousehold> createState() => _AddHouseholdState();
}

class _AddHouseholdState extends ConsumerState<AddHousehold> {
  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    Future<void> onCreateHousehold() async {
      final household = await HouseholdModel(name: nameController.text).save();
      // Switch the current household via the new API + mutation queue
      // (PATCH /v1/me).
      await ref
          .read(meControllerProvider)
          .setCurrentHousehold(household.id!);

      if (!context.mounted) return;
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
