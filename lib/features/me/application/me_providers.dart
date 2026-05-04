import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final meRepositoryProvider = Provider<MeRepository>((ref) {
  return MeRepository(firestore: ref.watch(firestoreProvider));
});

final meProvider = StreamProvider<Me?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(meRepositoryProvider).watch(auth.uid);
});

final currentHouseholdIdProvider = Provider<String?>((ref) {
  return ref.watch(meProvider).valueOrNull?.currentHouseholdId;
});

final householdIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(meProvider).valueOrNull?.householdIds ?? const <String>[];
});
