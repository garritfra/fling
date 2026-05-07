import 'package:dio/dio.dart';

/// The mutation-queue and call sites distinguish two failure shapes:
///
/// * [NetworkFailure] — no HTTP response landed (connection refused,
///   timeout, dns failure, etc.). Treated as transient: the queue keeps
///   the mutation pending and retries on the next connectivity event.
/// * [ApiFailure] — the server returned a non-2xx status. The status
///   code drives policy (4xx non-409 is dropped + rethrown; 409 stays
///   pending so the caller can resolve the conflict).
class NetworkFailure implements Exception {
  const NetworkFailure();
}

class ApiFailure implements Exception {
  const ApiFailure(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => 'ApiFailure($status, $code): $message';
}

/// Translate a Dio exception into one of the queue's failure types.
/// Pulls `error.code` and `error.message` out of the standard
/// `{error: {code, message}}` body shape the API emits.
Object dioToApiFailure(DioException e) {
  final status = e.response?.statusCode;
  if (status == null) return const NetworkFailure();
  final body = e.response?.data;
  String code = 'UNKNOWN';
  String message = e.message ?? '';
  if (body is Map && body['error'] is Map) {
    final err = body['error'] as Map;
    code = (err['code'] as String?) ?? code;
    message = (err['message'] as String?) ?? message;
  }
  return ApiFailure(status, code, message);
}
