import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/core/api/api_client.dart';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/data/household.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseAuthProvider =
    Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final meRepositoryProvider = FutureProvider<MeRepository>((ref) async {
  final mutations = await ref.watch(mutationQueueProvider.future);
  return MeRepository(
    firestore: ref.watch(firestoreProvider),
    api: ref.watch(flingApiProvider),
    mutations: mutations,
  );
});

final meProvider = StreamProvider<Me?>((ref) async* {
  // Wait for the first auth-state emission rather than reading
  // `valueOrNull`, which is null before the StreamProvider has fired its
  // first event (and would race the test harness).
  final auth = await ref.watch(authStateProvider.future);
  if (auth == null) {
    yield null;
    return;
  }
  final repo = await ref.watch(meRepositoryProvider.future);
  yield* repo.watch(auth.uid);
});

final currentHouseholdIdProvider = Provider<String?>((ref) {
  return ref.watch(meProvider).valueOrNull?.currentHouseholdId;
});

final householdIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(meProvider).valueOrNull?.householdIds ?? const <String>[];
});

/// Streams the [HouseholdModel] for the currently-active household. Emits
/// `null` while no household is selected. Phase 2 will move this provider
/// into `lib/features/households/`.
final currentHouseholdProvider = StreamProvider<HouseholdModel?>((ref) {
  final id = ref.watch(currentHouseholdIdProvider);
  if (id == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('households')
      .doc(id)
      .snapshots()
      .map((snap) =>
          snap.exists ? HouseholdModel.fromMap(snap.data() ?? {}, snap.id) : null);
});

class MeController {
  MeController(this._ref);
  final Ref _ref;

  Future<void> setCurrentHousehold(String householdId) async {
    final auth = _ref.read(firebaseAuthProvider).currentUser;
    if (auth == null) return;
    final repo = await _ref.read(meRepositoryProvider.future);
    await repo.setCurrentHouseholdId(auth.uid, householdId);
  }

  Future<void> setDisplayName(String displayName) async {
    final auth = _ref.read(firebaseAuthProvider).currentUser;
    if (auth == null) return;
    final repo = await _ref.read(meRepositoryProvider.future);
    await repo.setDisplayName(auth.uid, displayName);
  }
}

final meControllerProvider = Provider<MeController>(MeController.new);
