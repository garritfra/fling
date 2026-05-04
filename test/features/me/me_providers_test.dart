import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fling/features/me/application/me_providers.dart';
import 'package:fling/features/me/domain/me.dart';
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

    final container = ProviderContainer(overrides: [
      firestoreProvider.overrideWithValue(firestore),
      firebaseAuthProvider.overrideWithValue(auth),
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
