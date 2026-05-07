import 'dart:async';
import 'package:fling/core/api/mutation_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Connectivity {
  final controller = StreamController<bool>.broadcast();
  Stream<bool> get stream => controller.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue resolves before the call is invoked (fire-and-forget)',
      () async {
    // Regression test for https://github.com/garritfra/fling/issues/563:
    // `enqueue` must return as soon as the mutation is durably persisted,
    // not when the server has confirmed. Otherwise call sites awaiting it
    // block on the round-trip and the optimistic overlay never gets seen.
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    final callStarted = Completer<void>();
    final letCallFinish = Completer<void>();
    final enqueueDone = Completer<void>();

    unawaited(q.enqueue(MutationSpec(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async {
        callStarted.complete();
        await letCallFinish.future;
      },
    )).then((_) => enqueueDone.complete()));

    // `enqueue`'s future must resolve without the call having to finish.
    await enqueueDone.future;
    expect(callStarted.isCompleted, isTrue,
        reason: 'call should have started in the background');
    expect(letCallFinish.isCompleted, isFalse,
        reason: 'enqueue should not wait for the call to finish');
    letCallFinish.complete();
  });

  test('successful enqueue runs the call and clears pending', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    var calls = 0;
    await q.enqueue(MutationSpec(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async {
        calls++;
      },
    ));
    // The call runs in the background; wait for the queue to settle.
    await q.pending.firstWhere((l) => l.isEmpty);
    expect(calls, 1);
  });

  test('on transient failure the mutation stays pending until drain succeeds',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    var attempts = 0;
    await q.enqueue(MutationSpec(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async {
        attempts++;
        if (attempts < 2) throw const NetworkFailure();
      },
    ));
    // First attempt fails with NetworkFailure; mutation stays pending.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await q.pending.first).length, 1);
    // Connectivity event triggers a drain; second attempt succeeds.
    connectivity.controller.add(true);
    await q.pending.firstWhere((l) => l.isEmpty);
    expect(attempts, 2);
  });

  test(
      'on permanent failure (4xx non-409) the mutation is dropped and surfaced'
      ' on `failures`', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    final failureFuture = q.failures.first;
    await q.enqueue(MutationSpec(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': ''},
      call: (key) async =>
          throw const ApiFailure(400, 'BAD_REQUEST', 'too short'),
    ));
    final failure = await failureFuture;
    expect(failure.error.status, 400);
    expect(failure.error.code, 'BAD_REQUEST');
    expect(failure.mutation.type, 'me.patch');
    expect(failure.mutation.resourceKey, 'me/alice');
    expect(await q.pending.first, isEmpty);
  });

  test('persists pending mutations across instances', () async {
    SharedPreferences.setMockInitialValues({});
    var prefs = await SharedPreferences.getInstance();
    final connectivity1 = _Connectivity();
    final q1 = MutationQueueImpl(prefs: prefs, online: connectivity1.stream);
    // Enqueue a mutation that will keep failing (offline) so it stays
    // pending across queue instances.
    await q1.enqueue(MutationSpec(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'A'},
      call: (key) async => throw const NetworkFailure(),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await q1.pending.first).length, 1);

    // Recreate the queue from the same prefs; pending must survive.
    prefs = await SharedPreferences.getInstance();
    final connectivity2 = _Connectivity();
    final q2 = MutationQueueImpl(prefs: prefs, online: connectivity2.stream);
    expect((await q2.pending.first).length, 1);
  });

  test('overlay applies pending mutations to upstream', () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    final letCallFinish = Completer<void>();
    await q.enqueue(MutationSpec(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Optimistic'},
      call: (key) async {
        await letCallFinish.future;
      },
    ));
    // While the call is in flight the mutation is in the queue and the
    // overlay applies.
    final base = {'displayName': 'Old'};
    final overlaid = q.overlay<Map<String, Object?>>(
      base,
      (base, p) => {...base, ...p.body},
      resourceKey: 'me/alice',
    );
    expect(overlaid['displayName'], 'Optimistic');
    letCallFinish.complete();
  });
}
