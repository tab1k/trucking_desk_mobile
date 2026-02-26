class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.silent = false});

  final String message;
  final int? statusCode;
  final bool silent;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, silent: $silent)';
}
