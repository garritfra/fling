import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        accountEmail: Text(email!),
        accountName: Text(username ?? ""),
      );
    }

    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          buildHeader(),
          ListTile(
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('Listen'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/lists');
            },
          ),
          const Divider(
            height: 2.0,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          // Spacer(),
        ],
      ),
    );
  }
}
