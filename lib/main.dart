import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fling/pages/household_add.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fling/data/user.dart';
import 'package:fling/pages/list.dart';
import 'package:fling/pages/lists.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';

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

  Stream<FlingUser?> user = FlingUser.currentUser;

  runApp(MultiProvider(providers: [
    StreamProvider<FlingUser?>(
      create: (context) => user,
      initialData: null,
    )
  ], child: const FlingApp()));
}

class FlingApp extends StatelessWidget {
  const FlingApp({super.key});

  @override
  Widget build(BuildContext context) {
    var providers = [EmailAuthProvider()];

    final router = GoRouter(
      initialLocation:
          fba.FirebaseAuth.instance.currentUser == null ? '/login' : '/lists',
      routes: [
        GoRoute(path: '/lists', builder: (context, state) => const ListsPage()),
        GoRoute(path: '/list', builder: (context, state) => const ListPage()),
        GoRoute(
            path: '/household_add',
            builder: (context, state) => const AddHousehold()),
        GoRoute(
            path: '/login',
            builder: (context, state) => SignInScreen(
                  providers: providers,
                  actions: [
                    AuthStateChangeAction<SignedIn>((context, state) {
                      context.go('/');
                    }),
                    AuthStateChangeAction<UserCreated>((context, state) {
                      context.go('/');
                    }),
                  ],
                )),
      ],
    );

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
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
        title: 'Fling',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ?? ThemeData.light().colorScheme),
        darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ?? ThemeData.dark().colorScheme),
        routerConfig: router,
      ),
    );
  }
}
