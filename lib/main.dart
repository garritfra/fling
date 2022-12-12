import 'package:fling/data/data/user.dart';
import 'package:fling/pages/lists.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'pages/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlingUser? user = await FlingUser.currentUser;

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<FlingUser?>(create: (context) => user)
  ], child: const FlingApp()));
}

class FlingApp extends StatelessWidget {
  const FlingApp({super.key});

  @override
  Widget build(BuildContext context) {
    var providers = [EmailAuthProvider()];

    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'Fling',
      initialRoute:
          fba.FirebaseAuth.instance.currentUser == null ? '/login' : '/',
      routes: <String, WidgetBuilder>{
        '/login': (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushReplacementNamed(context, '/');
              }),
            ],
          );
        },
        '/lists': ((context) => const ListsPage())
      },
      home: const HomePage(),
    );
  }
}
