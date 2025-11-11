import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/auth/model/auth_response.dart';
import 'package:fura24.kz/features/auth/repositories/auth_repository.dart';
import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(authStorageProvider);
  return AuthController(
    repository: repository,
    storage: storage,
  );
});

enum SessionRefreshResult { noSession, refreshed, invalidRefresh, failed }

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({
    required this.repository,
    required this.storage,
  }) : super(const AsyncData(null));

  final AuthRepository repository;
  final AuthStorage storage;

  Future<bool> login({
    required String phoneNumber,
    required String password,
    String role = 'SENDER',
  }) async {
    state = const AsyncLoading();
    try {
      final response = await repository.login(
        phoneNumber: phoneNumber,
        password: password,
        role: role.toUpperCase(),
      );
      await _persistSession(response);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
    String? email,
    String role = 'SENDER',
  }) async {
    state = const AsyncLoading();
    try {
      final response = await repository.register(
        phoneNumber: phoneNumber,
        password: password,
        passwordConfirm: passwordConfirm,
        email: email?.isEmpty ?? true ? null : email,
        role: role.toUpperCase(),
      );
      await _persistSession(response);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    await storage.clearSession();
    _applyAuthToken(null);
    state = const AsyncData(null);
  }

  Future<SessionRefreshResult> refreshSession({AuthResponse? session}) async {
    session ??= await storage.readSession();
    if (session == null) {
      return SessionRefreshResult.noSession;
    }
    try {
      final updated = await repository.refreshTokens(
        refreshToken: session.refreshToken,
        user: session.user,
      );
      await _persistSession(updated);
      state = const AsyncData(null);
      return SessionRefreshResult.refreshed;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await storage.clearSession();
        _applyAuthToken(null);
        state = const AsyncData(null);
        return SessionRefreshResult.invalidRefresh;
      }
      state = const AsyncData(null);
      return SessionRefreshResult.failed;
    } catch (_) {
      state = const AsyncData(null);
      return SessionRefreshResult.failed;
    }
  }

  Future<AuthResponse?> readSession() async {
    final session = await storage.readSession();
    if (session != null && session.accessToken.isNotEmpty) {
      _applyAuthToken(session.accessToken);
    }
    return session;
  }

  Future<void> _persistSession(AuthResponse response) async {
    await storage.saveSession(response);
    _applyAuthToken(response.accessToken);
  }

  void _applyAuthToken(String? token) {
    repository.setAuthToken(token);
  }
}

String? authErrorMessage(AsyncValue<void> state) {
  return state.whenOrNull(
    error: (error, _) {
      if (error is ApiException) return error.message;
      return 'Не удалось выполнить операцию';
    },
  );
}
