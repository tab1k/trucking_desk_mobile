import 'package:dio/dio.dart';
import 'package:fura24.kz/core/error/global_error_provider.dart';

class GlobalErrorInterceptor extends Interceptor {
  final GlobalErrorNotifier notifier;

  GlobalErrorInterceptor(this.notifier);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Check for connection errors
    if (_isConnectionError(err)) {
      notifier.showNoConnection();
    }
    // Check for Server Errors (5xx)
    else if (_isServerError(err)) {
      notifier.showServerError(message: err.message);
    }

    super.onError(err, handler);
  }

  bool _isConnectionError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.error != null && err.error.toString().contains('SocketException'));
  }

  bool _isServerError(DioException err) {
    if (err.type == DioExceptionType.badResponse) {
      final statusCode = err.response?.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return true;
      }
    }
    return false;
  }
}
