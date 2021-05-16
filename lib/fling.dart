import 'package:flutter/material.dart';
import 'shopping_list.dart';

class FlingApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ShoppingList(title: 'Fling'),
    );
  }
}
