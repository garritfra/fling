import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:fling/core/api/failures.dart';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/features/me/data/me_mutations.dart';
import 'package:fling/features/me/domain/me.dart';
// fling_api exports its own built_value `Me`; the freezed domain Me is the
// one we operate on here.
import 'package:fling_api/fling_api.dart' hide Me;

class MeRepository {
  MeRepository({
    required this.firestore,
    required this.api,
    required this.mutations,
  });

  final FirebaseFirestore firestore;
  final FlingApi api;
  final MutationQueue mutations;

  /// Stream the caller's user doc. Pending mutations are folded on top
  /// so the UI stays optimistic until the Firestore stream catches up
  /// with the server-side write.
  Stream<Me?> watch(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      final base = Me.fromFirestoreDoc(uid, data);
      return mutations.overlay<Me>(
        base,
        (b, p) => _applyPatch(b, p.body),
        resourceKey: MeMutations.resourceKey(uid),
      );
    });
  }

  Me _applyPatch(Me base, Map<String, Object?> patch) {
    return base.copyWith(
      currentHouseholdId:
          (patch['currentHouseholdId'] as String?) ?? base.currentHouseholdId,
      displayName: (patch['displayName'] as String?) ?? base.displayName,
    );
  }

  Future<void> setCurrentHouseholdId(String uid, String householdId) =>
      _patchMe(uid, currentHouseholdId: householdId);

  Future<void> setDisplayName(String uid, String displayName) =>
      _patchMe(uid, displayName: displayName);

  Future<void> _patchMe(
    String uid, {
    String? currentHouseholdId,
    String? displayName,
  }) async {
    final body = <String, Object?>{
      if (currentHouseholdId != null) 'currentHouseholdId': currentHouseholdId,
      if (displayName != null) 'displayName': displayName,
    };
    await mutations.enqueue(MutationSpec<void>(
      type: MeMutations.patchType,
      resourceKey: MeMutations.resourceKey(uid),
      body: body,
      call: (key) async {
        try {
          await api.getMeApi().v1MePatch(
                patchMe: PatchMe((b) => b
                  ..currentHouseholdId = currentHouseholdId
                  ..displayName = displayName),
                headers: {'Idempotency-Key': key},
              );
        } on DioException catch (e) {
          throw dioToApiFailure(e);
        }
      },
    ));
  }
}
