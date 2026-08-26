import 'dart:async';

import 'package:fling/data/household.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the household-switcher dialog. Reactive against
/// `householdIdsProvider` so a freshly-created household appears as soon
/// as the `cacheJoinHousehold` trigger writes the new id into
/// `users/{uid}.households`, with no further user interaction.
Future<void> showHouseholdSwitcherDialog(
  BuildContext context, {
  required VoidCallback onAddHousehold,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Consumer(
      builder: (ctx, ref, _) {
        final l10n = AppLocalizations.of(ctx)!;
        final ids = ref.watch(householdIdsProvider);
        final activeId = ref.watch(currentHouseholdIdProvider);
        return FutureBuilder<List<HouseholdModel>>(
          future: Future.wait(ids.map(HouseholdModel.fromId)),
          builder: (ctx, snap) {
            final households = snap.data ?? const <HouseholdModel>[];
            return AlertDialog(
              title: Text(l10n.households),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...households.map((h) => ListTile(
                          onTap: () {
                            // Fire-and-forget: the mutation queue persists +
                            // applies the optimistic overlay synchronously
                            // (#563); awaiting here would re-introduce
                            // round-trip latency on the dialog.
                            unawaited(ref
                                .read(meControllerProvider)
                                .setCurrentHousehold(h.id!));
                            Navigator.pop(ctx);
                          },
                          title: Text(h.name),
                          trailing: h.id == activeId
                              ? const Icon(Icons.check)
                              : null,
                          leading: const Icon(Icons.house),
                        )),
                    ListTile(
                      onTap: () {
                        Navigator.pop(ctx);
                        onAddHousehold();
                      },
                      title: Text(l10n.household_add),
                      leading: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
