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

  test('enqueue runs the call once on success and removes from pending',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    var calls = 0;
    final result = await q.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async {
        calls++;
        return 1;
      },
    ));
    expect(result, 1);
    expect(calls, 1);
    expect(await q.pending.first, isEmpty);
  });

  test('on transient failure the mutation stays pending until drain succeeds',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    var attempts = 0;
    final f = q.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Alice'},
      call: (key) async {
        attempts++;
        if (attempts < 2) throw const NetworkFailure();
        return 1;
      },
    ));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await q.pending.first).length, 1);
    connectivity.controller.add(true);
    expect(await f, 1);
    expect(attempts, 2);
    expect(await q.pending.first, isEmpty);
  });

  test('on permanent failure (4xx non-409) the mutation is dropped and rethrown',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final connectivity = _Connectivity();
    final q = MutationQueueImpl(prefs: prefs, online: connectivity.stream);
    Object? caught;
    try {
      await q.enqueue(MutationSpec<int>(
        type: 'me.patch',
        resourceKey: 'me/alice',
        body: const {'displayName': ''},
        call: (key) async =>
            throw const ApiFailure(400, 'BAD_REQUEST', 'too short'),
      ));
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<ApiFailure>());
    expect(await q.pending.first, isEmpty);
  });

  test('persists pending mutations across instances', () async {
    SharedPreferences.setMockInitialValues({});
    var prefs = await SharedPreferences.getInstance();
    final connectivity1 = _Connectivity();
    final q1 = MutationQueueImpl(prefs: prefs, online: connectivity1.stream);
    // Enqueue without awaiting; force a transient failure by never going online.
    final completer = Completer<int>();
    unawaited(q1.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'A'},
      call: (key) async {
        if (!completer.isCompleted) throw const NetworkFailure();
        return 1;
      },
    )).then(completer.complete, onError: (_) {}));
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
    final completer = Completer<int>();
    unawaited(q.enqueue(MutationSpec<int>(
      type: 'me.patch',
      resourceKey: 'me/alice',
      body: const {'displayName': 'Optimistic'},
      call: (key) async {
        await completer.future;
        return 1;
      },
    )));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final base = {'displayName': 'Old'};
    final overlaid = q.overlay<Map<String, Object?>>(
      base,
      (base, p) => {...base, ...p.body},
      resourceKey: 'me/alice',
    );
    expect(overlaid['displayName'], 'Optimistic');
    completer.complete(1);
  });
}
