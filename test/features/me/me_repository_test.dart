import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fling/features/me/data/me_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeRepository.watch', () {
    test('emits Me with new field names when present', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('alice').set({
        'email': 'alice@example.com',
        'display_name': 'Alice',
        'household_ids': ['h1', 'h2'],
        'current_household_id': 'h1',
        'schema_version': 1,
      });
      final repo = MeRepository(firestore: firestore);
      final me = await repo.watch('alice').first;
      expect(me, isNotNull);
      expect(me!.uid, 'alice');
      expect(me.email, 'alice@example.com');
      expect(me.displayName, 'Alice');
      expect(me.householdIds, ['h1', 'h2']);
      expect(me.currentHouseholdId, 'h1');
    });

    test('falls back to legacy field names', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('alice').set({
        'households': ['h1'],
        'current_household': 'h1',
      });
      final repo = MeRepository(firestore: firestore);
      final me = await repo.watch('alice').first;
      expect(me!.householdIds, ['h1']);
      expect(me.currentHouseholdId, 'h1');
      expect(me.displayName, isNull);
      expect(me.email, isNull);
    });

    test('emits null when the doc does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final repo = MeRepository(firestore: firestore);
      final me = await repo.watch('ghost').first;
      expect(me, isNull);
    });
  });
}
