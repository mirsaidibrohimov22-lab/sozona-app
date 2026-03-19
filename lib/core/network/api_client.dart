// ═══════════════════════════════════════════════════════════════
// SO'ZONA — API Client (Cloud Functions bilan aloqa)
// ═══════════════════════════════════════════════════════════════

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/constants/app_constants.dart';
import 'package:my_first_app/core/services/logger_service.dart';

/// Cloud Functions ga HTTP so'rov yuborish uchun client.
///
/// Ichida:
/// - Auth token avtomatik qo'shiladi (interceptor)
/// - Xatolar loglanadi
/// - Timeout sozlangan
///
/// Bolaga tushuntirish:
/// Pochtachi — sen xat yozasan, u yetkazib beradi va javob olib keladi.
/// ApiClient ham shunday — Cloud Functions ga so'rov yuboradi va javob oladi.
class ApiClient {
  ApiClient({
    required String baseUrl,
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: AppConstants.apiTimeoutSeconds,
        ),
        receiveTimeout: const Duration(
          seconds: AppConstants.aiTimeoutSeconds,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ═══════════════════════════════════
    // INTERCEPTORS
    // ═══════════════════════════════════

    // 1. Auth Token Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = _firebaseAuth.currentUser;
            if (user != null) {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            LoggerService.warning('Failed to get auth token: $e');
          }
          handler.next(options);
        },
      ),
    );

    // 2. Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          LoggerService.debug(
            'API Request: ${options.method} ${options.path}',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          LoggerService.debug(
            'API Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          LoggerService.error(
            'API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
            error: error,
          );
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  /// GET so'rov yuborish.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// POST so'rov yuborish.
  ///
  /// AI Cloud Functions uchun asosiy metod.
  /// ```dart
  /// final response = await apiClient.post('/aiGenerateQuiz', data: {
  ///   'topic': 'Past Simple',
  ///   'level': 'A2',
  ///   'questionCount': 10,
  /// });
  /// ```
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  /// PUT so'rov yuborish.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      cancelToken: cancelToken,
    );
  }

  /// DELETE so'rov yuborish.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      cancelToken: cancelToken,
    );
  }
}

// ═══════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════

/// [ApiClient] instance provider.
///
/// baseUrl ni Firebase Console dan oling va environment ga qarab o'zgartiring.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    // Cloud Functions region — us-central1 default
    // Production da: https://us-central1-sozona-app.cloudfunctions.net
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://us-central1-sozona-app.cloudfunctions.net',
    ),
  );
});
