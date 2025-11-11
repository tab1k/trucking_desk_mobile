import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = AppConfig.apiBaseUrl.trim();
  final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  final options = BaseOptions(
    baseUrl: normalizedBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
    responseType: ResponseType.json,
    headers: {
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers.removeWhere((key, value) => value == null);
      return handler.next(options);
    },
  ));

  return dio;
});
