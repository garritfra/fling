import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fling/core/api/failures.dart';
import 'package:fling/core/api/idempotency_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:fling/core/api/failures.dart' show ApiFailure, NetworkFailure;

class MutationSpec {
  MutationSpec({
    required this.type,
    required this.resourceKey,
    required this.body,
    required this.call,
    this.idempotencyKey,
  });
  final String type;
  final String resourceKey;
  final Map<String, Object?> body;
  final String? idempotencyKey;
  final Future<void> Function(String idempotencyKey) call;
}

class PendingMutation {
  PendingMutation({
    required this.idempotencyKey,
    required this.type,
    required this.resourceKey,
    required this.body,
    required this.createdAt,
    this.attempts = 0,
  });
  final String idempotencyKey;
  final String type;
  final String resourceKey;
  final Map<String, Object?> body;
  final DateTime createdAt;
  int attempts;

  Map<String, Object?> toJson() => {
        'idempotencyKey': idempotencyKey,
        'type': type,
        'resourceKey': resourceKey,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };

  factory PendingMutation.fromJson(Map<String, Object?> j) => PendingMutation(
        idempotencyKey: j['idempotencyKey']! as String,
        type: j['type']! as String,
        resourceKey: j['resourceKey']! as String,
        body: Map<String, Object?>.from(j['body'] as Map),
        createdAt: DateTime.parse(j['createdAt']! as String),
        attempts: (j['attempts'] as int?) ?? 0,
      );
}

/// A mutation that the server rejected terminally (4xx non-409). Surfaced
/// on [MutationQueue.failures] so a top-level listener can show a
/// `FlingErrorSnackBar`. Matches the design spec §7.5 step 5.
class MutationFailure {
  const MutationFailure({required this.mutation, required this.error});
  final PendingMutation mutation;
  final ApiFailure error;
}

abstract class MutationQueue {
  /// Enqueue a mutation. Resolves once the mutation is **durably persisted
  /// to the local queue** — *not* when the server has confirmed. The HTTP
  /// call runs in the background; terminal failures arrive on [failures].
  ///
  /// Call sites must not `await` for the round-trip via this future. The
  /// optimistic overlay (see [overlay]) is what makes the new state visible
  /// to the UI immediately; pop dialogs / pages synchronously after this
  /// resolves.
  Future<void> enqueue(MutationSpec spec);

  Stream<List<PendingMutation>> get pending;

  /// Terminal failures (4xx non-409). Subscribers translate to UI
  /// (top-level `FlingErrorSnackBar`).
  Stream<MutationFailure> get failures;

  /// Apply pending mutations on top of an upstream snapshot. Resource-keyed.
  T overlay<T>(
    T upstream,
    T Function(T base, PendingMutation p) reduce, {
    required String resourceKey,
  });
  Future<void> drain();
}

class MutationQueueImpl implements MutationQueue {
  MutationQueueImpl({required this.prefs, required Stream<bool> online})
      : _online = online {
    _load();
    _onlineSub = _online.listen((isOnline) {
      if (isOnline) drain();
    });
  }

  static const _prefsKey = 'fling.mutation_queue.v1';
  final SharedPreferences prefs;
  final Stream<bool> _online;
  late final StreamSubscription<bool> _onlineSub;
  final _pendingController =
      StreamController<List<PendingMutation>>.broadcast();
  final _failureController = StreamController<MutationFailure>.broadcast();
  final List<PendingMutation> _queue = [];
  final Map<String, Future<void> Function(String)> _calls = {};

  void _load() {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<Map<String, Object?>>();
    _queue.addAll(list.map(PendingMutation.fromJson));
    _emit();
  }

  Future<void> _persist() async {
    await prefs.setString(
      _prefsKey,
      jsonEncode(_queue.map((p) => p.toJson()).toList()),
    );
  }

  void _emit() {
    _pendingController.add(List.unmodifiable(_queue));
  }

  @override
  Stream<List<PendingMutation>> get pending {
    Future<void>.microtask(_emit);
    return _pendingController.stream;
  }

  @override
  Stream<MutationFailure> get failures => _failureController.stream;

  @override
  Future<void> enqueue(MutationSpec spec) async {
    final key = spec.idempotencyKey ?? newIdempotencyKey();
    final p = PendingMutation(
      idempotencyKey: key,
      type: spec.type,
      resourceKey: spec.resourceKey,
      body: spec.body,
      createdAt: DateTime.now().toUtc(),
    );
    _queue.add(p);
    _calls[key] = spec.call;
    await _persist();
    _emit();
    // Run the network call in the background. The caller is unblocked the
    // moment the mutation is in the queue + persisted; the overlay makes
    // the new state visible immediately.
    unawaited(_runOne(p));
  }

  Future<void> _runOne(PendingMutation p) async {
    final call = _calls[p.idempotencyKey];
    if (call == null) return;
    p.attempts++;
    try {
      await call(p.idempotencyKey);
      _queue.removeWhere((q) => q.idempotencyKey == p.idempotencyKey);
      _calls.remove(p.idempotencyKey);
    } on NetworkFailure {
      // Stay pending; retried on next drain / connectivity event.
    } on ApiFailure catch (e) {
      // 409 is a server-side conflict — keep it pending so a future drain
      // (e.g. fresh idempotency key) can resolve it. All other 4xx are
      // terminal: drop the mutation and surface on `failures`.
      if (e.status >= 400 && e.status < 500 && e.status != 409) {
        _queue.removeWhere((q) => q.idempotencyKey == p.idempotencyKey);
        _calls.remove(p.idempotencyKey);
        _failureController.add(MutationFailure(mutation: p, error: e));
      }
    } catch (_) {
      // Unknown error — treat as transient.
    } finally {
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> drain() async {
    final snapshot = List<PendingMutation>.from(_queue);
    for (final p in snapshot) {
      await _runOne(p);
    }
  }

  @override
  T overlay<T>(
    T upstream,
    T Function(T base, PendingMutation p) reduce, {
    required String resourceKey,
  }) {
    var acc = upstream;
    for (final p in _queue) {
      if (p.resourceKey == resourceKey) acc = reduce(acc, p);
    }
    return acc;
  }

  Future<void> dispose() async {
    await _onlineSub.cancel();
    await _pendingController.close();
    await _failureController.close();
  }
}

/// Maps `connectivity_plus` results to a single boolean: any non-`none`
/// result counts as "online". Surfaced as a Riverpod `StreamProvider`
/// for UI consumers that want an `AsyncValue<bool>`.
final connectivityOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
});

final mutationQueueProvider = FutureProvider<MutationQueue>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Sidestep `connectivityOnlineProvider.stream` — the `.stream` accessor
  // is deprecated in Riverpod 2 and removed in 3.0.
  final online = Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
  final queue = MutationQueueImpl(prefs: prefs, online: online);
  ref.onDispose(queue.dispose);
  return queue;
});

/// Surface for terminal mutation failures. Exposed as a StreamProvider so
/// listeners (e.g. the top-level snackbar) can use `ref.listen` rather
/// than tracking a `StreamSubscription` themselves.
final mutationFailuresProvider = StreamProvider<MutationFailure>((ref) async* {
  final queue = await ref.watch(mutationQueueProvider.future);
  yield* queue.failures;
});
