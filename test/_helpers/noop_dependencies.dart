import 'package:fling/core/api/mutation_queue.dart';
import 'package:fling_api/fling_api.dart' hide Me;

/// `FlingApi` is a concrete class with a non-trivial constructor; tests that
/// don't actually issue API calls use this `noSuchMethod` stand-in instead
/// of constructing a real instance with a dummy Dio.
class NoopFlingApi implements FlingApi {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Pass-through queue: `enqueue` runs the spec's call once with a fixed
/// idempotency key; `overlay` is the identity. Equivalent to "no pending
/// mutations" — useful when a repo test cares about read paths only.
class NoopMutationQueue implements MutationQueue {
  @override
  Future<void> enqueue(MutationSpec spec) => spec.call('test');

  @override
  Stream<List<PendingMutation>> get pending => const Stream.empty();

  @override
  Stream<MutationFailure> get failures => const Stream.empty();

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
