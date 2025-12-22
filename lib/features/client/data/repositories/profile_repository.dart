import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final response = await _dio.get<Map<String, dynamic>>(_profilePath);
    final data = response.data;
    if (data == null) throw Exception('Пустой ответ профиля');
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile({
    Map<String, dynamic> updates = const {},
    XFile? avatarFile,
  }) async {
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
      options: options,
    );
    final responseData = response.data;
    if (responseData == null) throw Exception('Пустой ответ при обновлении профиля');
    return UserModel.fromJson(responseData);
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
      'vehicle_passport_front': await _multipartFromXFile(vehiclePassportFront),
      'vehicle_passport_back': await _multipartFromXFile(vehiclePassportBack),
      'id_front': await _multipartFromXFile(idFront),
      'id_back': await _multipartFromXFile(idBack),
    };
    final formData = FormData.fromMap(map);
    await _dio.post(
      'auth/verification/submit/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<MultipartFile> _multipartFromXFile(XFile file) async {
    final filename = (file.name.isNotEmpty ? file.name : 'avatar.jpg');

    if (!kIsWeb && file.path.isNotEmpty) {
      return MultipartFile.fromFile(file.path, filename: filename);
    }

    final bytes = await file.readAsBytes();
    return MultipartFile.fromBytes(bytes, filename: filename);
  }
}
