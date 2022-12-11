import 'package:flutter/material.dart';

import 'pages/login.dart';
import 'pages/home.dart';

void main() {
  runApp(const FlingApp());
}

class FlingApp extends StatelessWidget {
  const FlingApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'Fling',
      routes: <String, WidgetBuilder>{
        '/login': (context) => const LoginPage(),
      },
      home: const HomePage(),
    );
  }
}
