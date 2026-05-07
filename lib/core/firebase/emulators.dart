import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// True when the build was started with `--dart-define=FLING_USE_EMULATORS=true`.
const bool useEmulators =
    bool.fromEnvironment('FLING_USE_EMULATORS', defaultValue: false);

/// Host for the emulator suite. Override with
/// `--dart-define=FLING_EMULATOR_HOST=<host>` if running the emulator on
/// a different machine (e.g. in a VM).
const String _emulatorHost =
    String.fromEnvironment('FLING_EMULATOR_HOST', defaultValue: '127.0.0.1');

/// Wires Firebase Auth, Firestore, and Cloud Functions to their local
/// emulators when the build was started with
/// `--dart-define=FLING_USE_EMULATORS=true`. Idempotent and a no-op in
/// release builds even if the flag is set.
///
/// Must be called immediately after `Firebase.initializeApp(...)` and
/// before any Firebase API call. Each `useXEmulator` call mutates the
/// underlying singleton for the rest of the process lifetime.
Future<void> wireEmulatorsIfEnabled() async {
  if (!kDebugMode || !useEmulators) return;
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, 5001);
}
