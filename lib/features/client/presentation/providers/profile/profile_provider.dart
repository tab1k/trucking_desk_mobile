// Состояние профиля
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';
import 'package:fura24.kz/features/auth/model/auth_response.dart';
import 'package:fura24.kz/features/auth/model/user_model.dart';
import 'package:fura24.kz/features/client/data/repositories/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier для управления профилем
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository, this._ref) : super(ProfileState());

  final ProfileRepository _repository;
  final Ref _ref;

  // Загрузить профиль
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Используем данные из сохранённой сессии как быстрый источник
      final AuthStorage storage = _ref.read(authStorageProvider);
      final session = await storage.readSession();
      final sessionUser = session?.user;
      if (sessionUser != null) {
        state = state.copyWith(user: sessionUser);
      }

      final user = await _repository.fetchProfile();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      final fallbackUser = state.user;
      state = state.copyWith(
        error: fallbackUser == null ? e.toString() : null,
        isLoading: false,
        user: fallbackUser,
      );
    }
  }

  // Обновить профиль
  Future<void> updateProfile(
    Map<String, dynamic> updates, {
    XFile? avatarFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedUser = await _repository.updateProfile(
        updates: updates,
        avatarFile: avatarFile,
      );
      state = state.copyWith(user: updatedUser, isLoading: false);
      await _persistUser(updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Очистить ошибку
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Локальное обновление (без API)
  void updateUserLocally(UserModel newUser) {
    state = state.copyWith(user: newUser);
  }

  Future<void> _persistUser(UserModel user) async {
    try {
      final storage = _ref.read(authStorageProvider);
      final session = await storage.readSession();
      if (session == null) return;

      await storage.saveSession(AuthResponse(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: user,
      ));
    } catch (_) {
      // Тихо игнорируем ошибки сохранения, чтобы не ломать основной флоу
    }
  }
}

// Провайдер профиля
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository, ref);
});

// Провайдер только для данных пользователя (удобно для чтения)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(profileProvider).user;
});

// Провайдер для проверки авторизации
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
