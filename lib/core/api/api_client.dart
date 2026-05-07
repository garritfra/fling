import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fling_api/fling_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiBaseUrl {
  ApiBaseUrl(this.url);
  final String url;
}

final apiBaseUrlProvider = Provider<ApiBaseUrl>((_) {
  const url = String.fromEnvironment(
    'FLING_API_BASE_URL',
    defaultValue: 'https://us-central1-fling-list.cloudfunctions.net/api',
  );
  return ApiBaseUrl(url);
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
