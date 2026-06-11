import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../error/failures.dart';
import '../storage/token_storage.dart';

/// Thin wrapper around [Dio] that:
///  - points at the external API base URL,
///  - attaches the bearer token to every request,
///  - normalizes errors into [AppFailure].
///
/// The real HTTP repositories use this; the mock repositories ignore it.
class ApiClient {
  ApiClient(this._tokenStorage, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                contentType: 'application/json',
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // Verbose request/response/error logging so every API call and failure
    // (404/422/405/500…) is visible in the console while integrating against
    // the real backend. Debug builds only.
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('→ ${options.method} ${options.uri}');
            if (options.data != null) debugPrint('  body: ${options.data}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
                '← ${response.statusCode} ${response.requestOptions.method} '
                '${response.requestOptions.uri}');
            handler.next(response);
          },
          onError: (e, handler) {
            debugPrint(
                '✖ ${e.response?.statusCode ?? e.type} '
                '${e.requestOptions.method} ${e.requestOptions.uri}');
            debugPrint('  error: ${e.response?.data ?? e.message}');
            handler.next(e);
          },
        ),
      );
    }
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    return _run(() => _dio.get(path, queryParameters: query));
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    return _run(() => _dio.post(path, data: body));
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    return _run(() => _dio.put(path, data: body));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _run(() => _dio.delete(path));
  }

  Future<Map<String, dynamic>> _run(
      Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Laravel API Resources wrap a single resource in {"data": {...}}.
        // Unwrap it so repos read fields at the root. Collections
        // ({"data": [...]}) are left intact; their repos read the list
        // explicitly via json['data'].
        final inner = data['data'];
        return inner is Map<String, dynamic> ? inner : data;
      }
      if (data is List) return {'data': data};
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppFailure _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message;
    if (data is Map && data['message'] is String) {
      message = data['message'] as String;
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          message = 'Tiempo de espera agotado. Revisa tu conexión.';
          break;
        case DioExceptionType.connectionError:
          message = 'No se pudo conectar con el servidor.';
          break;
        default:
          message = 'Ocurrió un error inesperado.';
      }
    }
    return AppFailure(message, statusCode: status);
  }
}
