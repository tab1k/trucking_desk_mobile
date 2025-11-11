import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserModel> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('profile/me/');
    final data = response.data;
    if (data == null) throw Exception('Пустой ответ профиля');
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final response = await _dio.patch<Map<String, dynamic>>('profile/me/', data: updates);
    final data = response.data;
    if (data == null) throw Exception('Пустой ответ при обновлении профиля');
    return UserModel.fromJson(data);
  }
}
