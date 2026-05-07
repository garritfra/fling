import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling/features/me/domain/me.dart';
// `fling_api` exports its own generated `Me` model (built_value); we use
// the freezed domain `Me` from `features/me/domain/me.dart` instead, so we
// hide the API one to keep the namespace unambiguous.
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
        resourceKey: 'me/$uid',
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

  Future<void> setCurrentHouseholdId(String uid, String householdId) async {
    await mutations.enqueue(MutationSpec<void>(
      type: 'me.patch',
      resourceKey: 'me/$uid',
      body: {'currentHouseholdId': householdId},
      call: (key) async {
        try {
          await api.getMeApi().v1MePatch(
                patchMe: PatchMe((b) => b..currentHouseholdId = householdId),
                headers: {'Idempotency-Key': key},
              );
        } on DioException catch (e) {
          throw _toFailure(e);
        }
      },
    ));
  }

  Future<void> setDisplayName(String uid, String displayName) async {
    await mutations.enqueue(MutationSpec<void>(
      type: 'me.patch',
      resourceKey: 'me/$uid',
      body: {'displayName': displayName},
      call: (key) async {
        try {
          await api.getMeApi().v1MePatch(
                patchMe: PatchMe((b) => b..displayName = displayName),
                headers: {'Idempotency-Key': key},
              );
        } on DioException catch (e) {
          throw _toFailure(e);
        }
      },
    ));
  }

  /// Translate a `dio` failure into the queue's failure types so the
  /// retry/drop policy in [MutationQueueImpl] can act on it.
  Object _toFailure(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return const NetworkFailure();
    final body = e.response?.data;
    final code = (body is Map && body['error'] is Map)
        ? ((body['error'] as Map)['code'] as String? ?? 'UNKNOWN')
        : 'UNKNOWN';
    final message = (body is Map && body['error'] is Map)
        ? ((body['error'] as Map)['message'] as String? ?? e.message ?? '')
        : (e.message ?? '');
    return ApiFailure(status, code, message);
  }
}
