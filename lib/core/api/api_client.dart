import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling/core/firebase/emulators.dart';
import 'package:fling_api/fling_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiBaseUrl {
  ApiBaseUrl(this.url);
  final String url;
}

/// Resolves the REST-API base URL with the following precedence:
///
/// 1. `--dart-define=FLING_API_BASE_URL=<url>` — explicit override, wins
///    in every mode.
/// 2. `--dart-define=FLING_USE_EMULATORS=true` — auto-derives the local
///    Functions-emulator URL so dev builds don't need the explicit URL.
///    The project segment matches `firebase_options.dart` (`fling-list`),
///    which is also what the Auth-emulator will sign tokens against once
///    `useAuthEmulator(...)` runs in `wireEmulatorsIfEnabled`.
/// 3. Production default.
final apiBaseUrlProvider = Provider<ApiBaseUrl>((_) {
  const explicitOverride =
      String.fromEnvironment('FLING_API_BASE_URL', defaultValue: '');
  if (explicitOverride.isNotEmpty) return ApiBaseUrl(explicitOverride);
  if (useEmulators) {
    return ApiBaseUrl(
      'http://127.0.0.1:5001/fling-list/us-central1/api',
    );
  }
  return ApiBaseUrl('https://us-central1-fling-list.cloudfunctions.net/api');
});

class _BearerAuthInterceptor extends Interceptor {
  _BearerAuthInterceptor(this._auth);
  final FirebaseAuth _auth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

final flingApiProvider = Provider<FlingApi>((ref) {
  final base = ref.watch(apiBaseUrlProvider).url;
  final auth = FirebaseAuth.instance;
  final dio = Dio(BaseOptions(
    baseUrl: base,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
  dio.interceptors.add(_BearerAuthInterceptor(auth));
  return FlingApi(dio: dio);
});
