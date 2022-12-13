import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fling/data/data/user.dart';
import 'package:fling/pages/list.dart';
import 'package:fling/pages/lists.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';

import 'pages/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    // Force disable Crashlytics collection while doing every day development.
    // Temporarily toggle this to true if you want to test crash reporting in your app.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

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
      localizationsDelegates: const [
        AppLocalizations.delegate, // Add this line
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('de', ''),
      ],
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
        '/lists': ((context) => const ListsPage()),
        '/list': ((context) => const ListPage())
      },
      home: const HomePage(),
    );
  }
}
