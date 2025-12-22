import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/auth/model/auth_response.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio: dio);
});

class AuthRepository {
  const AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<AuthResponse> login({
    required String login,
    required String password,
    String role = 'SENDER',
  }) async {
    return _postAuth(
      endpoint: 'auth/login/',
      data: {
        'login': login,
        'password': password,
        'role': role,
      },
    );
  }

  Future<AuthResponse> register({
    required String login,
    required String password,
    required String passwordConfirm,
    String? email,
    String role = 'SENDER',
    String? referralCode,
  }) async {
    return _postAuth(
      endpoint: 'auth/register/',
      data: {
        'login': login,
        'password': password,
        'password_confirm': passwordConfirm,
        'role': role,
        if (email != null) 'email': email,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      },
    );
  }

  Future<Map<String, String?>> requestPasswordReset({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/password/reset/',
        data: {'email': email},
      );
      final body = response.data ?? {};
      return {
        'uid': body['uid'] as String?,
        'token': body['token'] as String?,
      };
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException('Не удалось отправить письмо для сброса пароля');
    }
  }

  Future<void> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      await _dio.post(
        'auth/password/reset/confirm/',
        data: {
          'uid': uid,
          'token': token,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        },
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException('Не удалось сбросить пароль. Попробуйте снова.');
    }
  }

  Future<AuthResponse> refreshTokens({
    required String refreshToken,
    required UserModel user,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final body = response.data;
      if (body == null) {
        throw ApiException('Пустой ответ от сервера', statusCode: response.statusCode);
      }

      final newAccess = body['access'] as String?;
      final newRefresh = body['refresh'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        throw ApiException('Сервер не вернул новый токен доступа', statusCode: response.statusCode);
      }

      return AuthResponse(
        accessToken: newAccess,
        refreshToken: newRefresh?.isNotEmpty == true ? newRefresh! : refreshToken,
        user: user,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (e) {
      throw ApiException('Не удалось обновить сессию. Попробуйте позже.');
    }
  }

  Future<AuthResponse> _postAuth({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: data,
      );

      final body = response.data;
      if (body == null) {
        throw ApiException('Пустой ответ от сервера', statusCode: response.statusCode);
      }

      return AuthResponse.fromJson(body);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (e) {
      throw ApiException('Не удалось выполнить запрос. Попробуйте позже.');
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await _dio.post(
        'auth/profile/delete/',
        data: {'password': password},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException('Не удалось удалить аккаунт. Попробуйте снова.');
    }
  }

  String _extractErrorMessage(DioException exception) {
    final responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      if (responseData['error'] is String) {
        return responseData['error'] as String;
      }
      if (responseData['detail'] is String) {
        return responseData['detail'] as String;
      }
      if (responseData.values.isNotEmpty) {
        final firstValue = responseData.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          final value = firstValue.first;
          if (value is String) return value;
        } else if (firstValue is String) {
          return firstValue;
        }
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания ответа сервера';
      case DioExceptionType.badResponse:
        return 'Сервер вернул ошибку';
      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером';
      default:
        return 'Произошла неизвестная ошибка';
    }
  }
}
