import 'package:fling/data/household.dart';
import 'package:fling/data/template.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/features/me/presentation/household_switcher_dialog.dart';
import 'package:fling/l10n/app_localizations.dart';
import 'package:fling/layout/drawer.dart';
import 'package:fling/pages/template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemplatesPage extends ConsumerStatefulWidget {
  const TemplatesPage({super.key});

  @override
  ConsumerState<TemplatesPage> createState() => _TemplatesPageState();
}

enum HouseholdMenuListAction {
  inviteUser,
  deleteHousehold,
}

class _TemplatesPageState extends ConsumerState<TemplatesPage> {
  @override
  Widget build(BuildContext context) {
    var l10n = AppLocalizations.of(context)!;

    void onAddhousehold() {
      Navigator.pushNamed(context, "/household_add");
    }

    void showTemplateActionsDialog(FlingTemplateModel template) {
      showDialog(
          context: context,
          builder: ((context) => AlertDialog(
                title: Text(l10n.template_delete),
                content: Text(l10n.action_sure),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_cancel)),
                  TextButton(
                      onPressed: () {
                        template.delete();
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_delete)),
                ],
              )));
    }

    Widget buildTemplates(HouseholdModel household) {
      return Expanded(
        child: StreamBuilder(
            stream: household.templates,
            builder: (context, snapshot) {
              var templates = snapshot.data ?? [];
              templates.sort((a, b) => a.name.compareTo(b.name));

              return ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (BuildContext context, int index) {
                    FlingTemplateModel template = templates.elementAt(index);

                    return ListTile(
                      onTap: () => Navigator.pushNamed(context, '/template',
                          arguments: TemplatePageArguments(template)),
                      onLongPress: () =>
                          showTemplateActionsDialog(template),
                      key: Key(template.id ?? template.name),
                      title: Text(template.name),
                    );
                  });
            }),
      );
    }

    Widget buildEmptyHouseholds() {
      return Column(
        children: [
          Text(l10n.household_empty),
          TextButton(
              onPressed: onAddhousehold,
              child: Text(l10n.household_create_first))
        ],
      );
    }

    void showDeleteHouseholdDialog(HouseholdModel household) {
      showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              title: Text(l10n.template_delete),
              content: Text(l10n.action_sure),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_cancel)),
                TextButton(
                    onPressed: () {
                      household.leave();
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.action_delete)),
              ],
            )),
      );
    }

    void showInviteDialog() {
      TextEditingController inviteEmailController = TextEditingController();
      NavigatorState navigator = Navigator.of(context);

      Future<void> onInviteUserPressed() async {
        final householdId = ref.read(currentHouseholdIdProvider);
        if (householdId != null) {
          final household = await HouseholdModel.fromId(householdId);
          await household.inviteByEmail(inviteEmailController.text);
        }
        navigator.pop();
      }

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(l10n.user_invite),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_cancel)),
                  TextButton(
                      onPressed: () {
                        onInviteUserPressed();
                      },
                      child: Text(l10n.action_done)),
                ],
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextField(
                      decoration:
                          InputDecoration(hintText: l10n.user_invite_hint),
                      controller: inviteEmailController,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ));
    }

    Future<void> showHouseholdSwitcher() => showHouseholdSwitcherDialog(
          context,
          onAddHousehold: onAddhousehold,
        );

    onAddTemplatePressed() {
      TextEditingController textController = TextEditingController();
      NavigatorState navigator = Navigator.of(context);
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(l10n.template_create),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.action_cancel)),
                  TextButton(
                      onPressed: () async {
                        final householdId =
                            ref.read(currentHouseholdIdProvider);

                        if (householdId != null) {
                          FlingTemplateModel(
                                  householdId: householdId,
                                  name: textController.text)
                              .save();
                        }
                        navigator.pop();
                      },
                      child: Text(l10n.action_done)),
                ],
                content: TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(hintText: l10n.item_name),
                  keyboardType: TextInputType.emailAddress,
                ),
              ));
    }

    final HouseholdModel? household =
        ref.watch(currentHouseholdProvider).valueOrNull;

    Widget buildSwitchHouseholdAction() {
      return IconButton(
          onPressed: showHouseholdSwitcher,
          icon: const Icon(Icons.swap_horiz));
    }

    Widget buildMoreAction() {
      return PopupMenuButton(
          onSelected: (selection) {
            switch (selection) {
              case HouseholdMenuListAction.inviteUser:
                showInviteDialog();
                break;
              case HouseholdMenuListAction.deleteHousehold:
                if (household != null) {
                  showDeleteHouseholdDialog(household);
                }
                break;
            }
          },
          itemBuilder: (context) => [
                PopupMenuItem(
                    value: HouseholdMenuListAction.inviteUser,
                    child: Text(l10n.user_invite)),
                PopupMenuItem(
                    value: HouseholdMenuListAction.deleteHousehold,
                    child: Text(l10n.household_leave))
              ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.templates),
        actions: household != null
            ? [
                buildSwitchHouseholdAction(),
                buildMoreAction(),
              ]
            : null,
      ),
      floatingActionButton: household != null
          ? FloatingActionButton(
              onPressed: onAddTemplatePressed,
              child: const Icon(Icons.add))
          : null,
      drawer: const FlingDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (household != null)
              buildTemplates(household)
            else
              buildEmptyHouseholds(),
          ],
        ),
      ),
    );
  }
}
