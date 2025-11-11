import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fura24.kz/features/auth/model/auth_response.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return SharedPrefsAuthStorage();
});

abstract class AuthStorage {
  Future<void> saveSession(AuthResponse response);
  Future<AuthResponse?> readSession();
  Future<void> clearSession();
}

class SharedPrefsAuthStorage implements AuthStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user';

  @override
  Future<void> saveSession(AuthResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, response.accessToken);
    await prefs.setString(_refreshKey, response.refreshToken);
    await prefs.setString(_userKey, jsonEncode(response.user.toJson()));
  }

  @override
  Future<AuthResponse?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);
    final userJson = prefs.getString(_userKey);

    if (access == null || refresh == null || userJson == null) {
      return null;
    }

    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    return AuthResponse(
      accessToken: access,
      refreshToken: refresh,
      user: UserModel.fromJson(userMap),
    );
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }
}
