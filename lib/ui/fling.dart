import 'package:fling/ui/config.dart';
import 'package:fling/ui/recipe_list.dart';
import 'package:fling/ui/shopping_list.dart';
import 'package:flutter/material.dart';

class FlingApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'Fling',
      routes: <String, WidgetBuilder>{
        '/config': (context) => ConfigPage(),
        '/recipes': (context) => RecipeList(),
      },
      home: ShoppingList(title: 'Fling'),
    );
  }
}
