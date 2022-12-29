import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FlingDrawer extends StatelessWidget {
  const FlingDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    String? email = FirebaseAuth.instance.currentUser?.email;
    String? username = FirebaseAuth.instance.currentUser?.displayName;

    buildHeader() {
      return UserAccountsDrawerHeader(
        decoration: const BoxDecoration(
          color: Colors.blue,
        ),
        accountEmail: Text(email ?? ""),
        accountName: Text(username ?? ""),
      );
    }

    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: Column(
        children: [
          Expanded(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                buildHeader(),
                ListTile(
                  title: Text(AppLocalizations.of(context)!.lists),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/lists');
                  },
                ),

                // Spacer(),
              ],
            ),
          ),
          const Divider(
            height: 2.0,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Info"),
            onTap: () {
              PackageInfo.fromPlatform().then((packageInfo) => {
                    showAboutDialog(
                        context: context,
                        applicationVersion: packageInfo.version)
                  });
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              FirebaseAuth.instance.signOut();
              // TODO: the app should listen for logout changes
              Navigator.popAndPushNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
