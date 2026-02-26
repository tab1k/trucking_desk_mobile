import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/auth/model/auth_response.dart';
import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';

/// Interceptor that retries 401/403 once after refreshing tokens.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({required this.ref, required this.dio});

  final Ref ref;
  final Dio dio;

  bool _isRefreshing = false;
  final List<RequestOptions> _queued = [];
  final List<RequestOptions> _failedMultipart = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldRefresh(err)) {
      _handleRefresh(err, handler);
      return;
    }
    super.onError(err, handler);
  }

  bool _shouldRefresh(DioException err) {
    final status = err.response?.statusCode;
    // Refresh only on 401 (unauthorized). 403 errors are often real permission
    // denials (e.g., user role mismatch) and trying to refresh them causes
    // endless retries and hanging requests.
    return status == 401 && !_isLoginOrRefresh(err.requestOptions.path);
  }

  bool _isLoginOrRefresh(String path) {
    return path.contains('auth/login') ||
        path.contains('auth/register') ||
        path.contains('auth/phone/verify') ||
        path.contains('auth/token/refresh');
  }

  Future<void> _handleRefresh(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isMultipart = _isMultipart(request);

    if (isMultipart) {
      _failedMultipart.add(request);
    } else {
      _queued.add(request);
    }

    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final newSession = await _refreshTokens();
      if (newSession == null) {
        _failQueued(handler, err);
        return;
      }

      // Update auth header
      dio.options.headers['Authorization'] = 'Bearer ${newSession.accessToken}';

      // Retry queued
      for (final request in List<RequestOptions>.from(_queued)) {
        try {
          final response = await dio.fetch(_recreateOptions(request));
          handler.resolve(response);
        } catch (e) {
          if (e is DioException) {
            handler.next(e);
          } else {
            handler.reject(err);
          }
        }
      }

      // Retry multipart by rebuilding FormData
      for (final request in List<RequestOptions>.from(_failedMultipart)) {
        try {
          final rebuilt = await _rebuildMultipart(request);
          final response = await dio.fetch(rebuilt);
          handler.resolve(response);
        } catch (e) {
          if (e is DioException) {
            handler.next(e);
          } else {
            handler.reject(err);
          }
        }
      }
    } finally {
      _queued.clear();
      _failedMultipart.clear();
      _isRefreshing = false;
    }
  }

  bool _isMultipart(RequestOptions request) {
    final data = request.data;
    if (data == null) return false;
    if (data is Stream) return true;
    if (data is FormData) return true;
    return false;
  }

  RequestOptions _recreateOptions(RequestOptions request) {
    return request..headers['Authorization'] = dio.options.headers['Authorization'];
  }

  Future<RequestOptions> _rebuildMultipart(RequestOptions request) async {
    final data = request.data;
    if (data is FormData) {
      final rebuilt = FormData();
      for (final field in data.fields) {
        rebuilt.fields.add(MapEntry(field.key, field.value));
      }
      for (final file in data.files) {
        rebuilt.files.add(MapEntry(file.key, file.value));
      }
      return request
        ..data = rebuilt
        ..headers['Authorization'] = dio.options.headers['Authorization'];
    }
    // Fallback: return original request
    return request;
  }

  Future<AuthResponse?> _refreshTokens() async {
    final storage = ref.read(authStorageProvider);
    final session = await storage.readSession();
    if (session == null || session.refreshToken.isEmpty) return null;

    final controller = ref.read(authControllerProvider.notifier);
    final result = await controller.refreshSession(session: session);
    if (result == SessionRefreshResult.refreshed) {
      return await storage.readSession();
    }
    return null;
  }

  void _failQueued(ErrorInterceptorHandler handler, DioException err) {
    for (final request in _queued) {
      handler.next(err.copyWith(requestOptions: request));
    }
    for (final request in _failedMultipart) {
      handler.next(err.copyWith(requestOptions: request));
    }
    _queued.clear();
    _failedMultipart.clear();
  }
}
