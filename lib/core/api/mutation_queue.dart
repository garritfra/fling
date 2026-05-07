import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fling/core/api/failures.dart';
import 'package:fling/core/api/idempotency_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:fling/core/api/failures.dart' show ApiFailure, NetworkFailure;

class MutationSpec<T> {
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
  final Future<T> Function(String idempotencyKey) call;
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

abstract class MutationQueue {
  Future<T> enqueue<T>(MutationSpec<T> spec);
  Stream<List<PendingMutation>> get pending;

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
  final _controller = StreamController<List<PendingMutation>>.broadcast();
  final List<PendingMutation> _queue = [];
  final Map<String, Completer<dynamic>> _completers = {};
  final Map<String, Future<dynamic> Function(String)> _calls = {};

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
    _controller.add(List.unmodifiable(_queue));
  }

  @override
  Stream<List<PendingMutation>> get pending {
    Future<void>.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<T> enqueue<T>(MutationSpec<T> spec) async {
    final key = spec.idempotencyKey ?? newIdempotencyKey();
    final p = PendingMutation(
      idempotencyKey: key,
      type: spec.type,
      resourceKey: spec.resourceKey,
      body: spec.body,
      createdAt: DateTime.now().toUtc(),
    );
    _queue.add(p);
    final completer = Completer<T>();
    _completers[key] = completer;
    _calls[key] = spec.call;
    await _persist();
    _emit();
    unawaited(_runOne(p));
    return completer.future;
  }

  Future<void> _runOne(PendingMutation p) async {
    final call = _calls[p.idempotencyKey];
    final completer = _completers[p.idempotencyKey];
    if (call == null || completer == null) return;
    p.attempts++;
    try {
      final result = await call(p.idempotencyKey);
      _queue.removeWhere((q) => q.idempotencyKey == p.idempotencyKey);
      _completers.remove(p.idempotencyKey);
      _calls.remove(p.idempotencyKey);
      completer.complete(result);
    } on NetworkFailure {
      // Stay pending; retried on next drain / connectivity event.
    } on ApiFailure catch (e) {
      // 409 is a server-side conflict — keep it pending so the caller can
      // resolve it (e.g. fresh idempotency key). All other 4xx are caller
      // errors; drop and rethrow so the caller sees them.
      if (e.status >= 400 && e.status < 500 && e.status != 409) {
        _queue.removeWhere((q) => q.idempotencyKey == p.idempotencyKey);
        _completers.remove(p.idempotencyKey);
        _calls.remove(p.idempotencyKey);
        completer.completeError(e);
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
    await _controller.close();
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
