import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/config/app_config.dart';
import 'package:fura24.kz/core/error/global_error_provider.dart';
import 'package:fura24.kz/core/network/global_error_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = AppConfig.apiBaseUrl.trim();
  final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  final options = BaseOptions(
    baseUrl: normalizedBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    contentType: 'application/json',
    responseType: ResponseType.json,
    headers: {'Accept': 'application/json'},
  );

  final dio = Dio(options);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers.removeWhere((key, value) => value == null);
        return handler.next(options);
      },
    ),
  );

  // Add Global Error Interceptor
  final errorNotifier = ref.read(globalErrorProvider.notifier);
  dio.interceptors.add(GlobalErrorInterceptor(errorNotifier));

  return dio;
});
