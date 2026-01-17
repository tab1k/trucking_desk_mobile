import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';
import 'package:image_picker/image_picker.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;
  static const _profilePath = 'auth/profile/';

  Future<UserModel> fetchProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_profilePath);
      final data = response.data;
      if (data == null) {
        throw ApiException(
          tr('repository.profile.fetch_empty'),
          statusCode: response.statusCode,
        );
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(tr('repository.profile.fetch_error'));
    }
  }

  Future<UserModel> updateProfile({
    Map<String, dynamic> updates = const {},
    XFile? avatarFile,
  }) async {
    try {
      dynamic data = updates;
      Options? options;

      if (avatarFile != null) {
        final map = Map<String, dynamic>.from(updates);
        map['avatar'] = await _multipartFromXFile(avatarFile);
        data = FormData.fromMap(map);
        options = Options(contentType: 'multipart/form-data');
      }

      final response = await _dio.patch<Map<String, dynamic>>(
        _profilePath,
        data: data,
        options:
            options?.copyWith(
              sendTimeout: const Duration(seconds: 120),
              receiveTimeout: const Duration(seconds: 120),
            ) ??
            Options(
              sendTimeout: const Duration(seconds: 120),
              receiveTimeout: const Duration(seconds: 120),
            ),
      );
      final responseData = response.data;
      if (responseData == null) {
        throw ApiException(
          tr('repository.profile.update_empty'),
          statusCode: response.statusCode,
        );
      }
      return UserModel.fromJson(responseData);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(tr('repository.profile.update_error'));
    }
  }

  Future<void> submitDriverVerification({
    required String firstName,
    required String lastName,
    String? middleName,
    required String email,
    required String phoneNumber,
    required String licenseNumber,
    required String vehiclePassportNumber,
    required String idNumber,
    required XFile licenseFront,
    required XFile licenseBack,
    required XFile vehiclePassportFront,
    required XFile vehiclePassportBack,
    required XFile idFront,
    required XFile idBack,
  }) async {
    try {
      final map = {
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName ?? '',
        'email': email,
        'phone_number': phoneNumber,
        'license_number': licenseNumber,
        'vehicle_passport_number': vehiclePassportNumber,
        'id_number': idNumber,
        'license_front': await _multipartFromXFile(licenseFront),
        'license_back': await _multipartFromXFile(licenseBack),
        'vehicle_passport_front': await _multipartFromXFile(
          vehiclePassportFront,
        ),
        'vehicle_passport_back': await _multipartFromXFile(vehiclePassportBack),
        'id_front': await _multipartFromXFile(idFront),
        'id_back': await _multipartFromXFile(idBack),
      };
      final formData = FormData.fromMap(map);
      await _dio.post(
        'auth/verification/submit/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(tr('repository.profile.verification_error'));
    }
  }

  Future<MultipartFile> _multipartFromXFile(XFile file) async {
    final filename = (file.name.isNotEmpty ? file.name : 'avatar.jpg');

    if (!kIsWeb && file.path.isNotEmpty) {
      return MultipartFile.fromFile(file.path, filename: filename);
    }

    final bytes = await file.readAsBytes();
    return MultipartFile.fromBytes(bytes, filename: filename);
  }

  String _extractErrorMessage(DioException exception) {
    final response = exception.response;
    if (response?.data is Map) {
      final data = response!.data as Map;
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return tr('repository.profile.network_error');
  }
}
