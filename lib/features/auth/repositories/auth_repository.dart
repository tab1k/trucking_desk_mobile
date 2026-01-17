import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/auth/model/auth_response.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';
import 'package:easy_localization/easy_localization.dart';

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
      data: {'login': login, 'password': password, 'role': role},
    );
  }

  Future<void> requestPhoneVerification({required String phoneNumber}) async {
    try {
      await _dio.post(
        'auth/phone/verify/request/',
        data: {'phone_number': phoneNumber},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException(tr('auth_errors.send_code_failed'));
    }
  }

  Future<AuthResponse> confirmPhoneVerification({
    required String phoneNumber,
    required String pin,
    required String password,
    String?
    passwordConfirm, // Backend might not strict require this if validated on client, but let's pass if needed or just password
    String role = 'SENDER',
    String? firstName,
    String? lastName,
    String? email,
    String? referralCode,
  }) async {
    // Prepare data mirroring the backend serializer
    final data = {
      'phone_number': phoneNumber,
      'pin': pin,
      'password': password,
      'password_confirm': passwordConfirm ?? password,
      'role': role,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (referralCode != null && referralCode.isNotEmpty)
        'referral_code': referralCode,
    };

    return _postAuth(endpoint: 'auth/phone/verify/confirm/', data: data);
  }

  Future<AuthResponse> register({
    required String login,
    required String password,
    required String passwordConfirm,
    String? email,
    String role = 'SENDER',
    String? referralCode,
  }) async {
    // This method might be deprecated if we fully switch to SMS flow,
    // but keep it for now or modify it to throw error if used directly.
    return _postAuth(
      endpoint: 'auth/register/',
      data: {
        'login':
            login, // Note: Backend expects phone_number usually for users, but existing code used 'login'
        'password': password,
        'password_confirm': passwordConfirm,
        'role': role,
        if (email != null) 'email': email,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      },
    );
  }

  Future<Map<String, String?>> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/password/reset/',
        data: {'email': email},
      );
      final body = response.data ?? {};
      return {'uid': body['uid'] as String?, 'token': body['token'] as String?};
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException(tr('auth_errors.send_reset_email_failed'));
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
      throw ApiException(tr('auth_errors.reset_password_failed'));
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
        throw ApiException(
          tr('auth_errors.empty_response'),
          statusCode: response.statusCode,
        );
      }

      final newAccess = body['access'] as String?;
      final newRefresh = body['refresh'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        throw ApiException(
          tr('auth_errors.token_refresh_failed'),
          statusCode: response.statusCode,
        );
      }

      return AuthResponse(
        accessToken: newAccess,
        refreshToken: newRefresh?.isNotEmpty == true
            ? newRefresh!
            : refreshToken,
        user: user,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (e) {
      throw ApiException(tr('auth_errors.session_update_failed'));
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
        throw ApiException(
          tr('auth_errors.empty_response'),
          statusCode: response.statusCode,
        );
      }

      return AuthResponse.fromJson(body);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (e) {
      throw ApiException(tr('auth_errors.request_failed'));
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await _dio.post('auth/profile/delete/', data: {'password': password});
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException(tr('auth_errors.delete_account_failed'));
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
        return tr('auth_errors.timeout');
      case DioExceptionType.badResponse:
        return tr('auth_errors.server_error');
      case DioExceptionType.connectionError:
        return tr('auth_errors.connection_error');
      default:
        return tr('auth_errors.unknown_error');
    }
  }
}
