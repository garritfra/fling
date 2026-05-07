import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:fling/features/me/domain/me.dart';
import 'package:fling_api/fling_api.dart' hide Me;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("meProvider streams the current auth user's doc", () async {
    final firestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: 'alice', email: 'alice@example.com');
    final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    await firestore.collection('users').doc('alice').set({
      'email': 'alice@example.com',
      'household_ids': ['h1'],
      'current_household_id': 'h1',
    });

    // Hand-build the repo so we don't drag SharedPreferences /
    // connectivity_plus / FirebaseAuth into a unit test.
    final repo = MeRepository(
      firestore: firestore,
      api: _NoopApi(),
      mutations: _NoopQueue(),
    );

    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      firebaseAuthProvider.overrideWithValue(auth),
      meRepositoryProvider.overrideWith((_) async => repo),
    ]);
    addTearDown(container.dispose);

    // A listener is required to keep the provider reactive to dependency changes.
    final sub = container.listen(meProvider, (_, __) {}, fireImmediately: true);
    addTearDown(sub.close);

    final me = await container.read(meProvider.future);
    expect(me, isA<Me>());
    expect(me!.uid, 'alice');
    expect(me.currentHouseholdId, 'h1');
  });
}

class _NoopApi implements FlingApi {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _NoopQueue implements MutationQueue {
  @override
  Future<T> enqueue<T>(MutationSpec<T> spec) => spec.call('test');

  @override
  Stream<List<PendingMutation>> get pending => const Stream.empty();

  @override
  T overlay<T>(
    T upstream,
    T Function(T base, PendingMutation p) reduce, {
    required String resourceKey,
  }) =>
      upstream;

  @override
  Future<void> drain() async {}
}
