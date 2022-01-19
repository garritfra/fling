import 'package:flutter/material.dart';

class FlingDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Fling'),
          ),
          ListTile(
            title: const Text('Einkaufsliste'),
            onTap: () {
              Navigator.popAndPushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('Rezeptbuch'),
            onTap: () {
              Navigator.popAndPushNamed(context, '/recipes');
            },
          ),
          Divider(
            thickness: 2.0,
          ),
          ListTile(
            title: const Text('Einstellungen'),
            onTap: () {
              Navigator.pushNamed(context, '/config');
            },
          ),
        ],
      ),
    );
  }
}
