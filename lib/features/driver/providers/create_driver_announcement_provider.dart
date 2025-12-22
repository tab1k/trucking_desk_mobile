import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/driver_announcement_repository.dart';
import 'package:fura24.kz/features/driver/domain/models/create_driver_announcement_request.dart';
import 'package:fura24.kz/features/notifications/providers/notifications_provider.dart';

final createDriverAnnouncementControllerProvider =
    StateNotifierProvider<CreateDriverAnnouncementController, AsyncValue<void>>(
  (ref) {
    final repository = ref.watch(driverAnnouncementRepositoryProvider);
    final notificationsController =
        ref.read(notificationsControllerProvider.notifier);
    return CreateDriverAnnouncementController(
      repository: repository,
      notificationsController: notificationsController,
    );
  },
);

class CreateDriverAnnouncementController
    extends StateNotifier<AsyncValue<void>> {
  CreateDriverAnnouncementController({
    required this.repository,
    required this.notificationsController,
  })
    : super(const AsyncData(null));

  final DriverAnnouncementRepository repository;
  final NotificationsController notificationsController;

  Future<bool> submit(CreateDriverAnnouncementRequest request) async {
    state = const AsyncLoading();
    try {
      final announcement = await repository.createAnnouncement(request);
      // Локальный пуш в список уведомлений, если сервер не вернул.
      await notificationsController.addAnnouncementNotification(announcement);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> update(String id, CreateDriverAnnouncementRequest request) async {
    state = const AsyncLoading();
    try {
      final announcement = await repository.updateAnnouncement(id, request);
      // Не пушим уведомление при редактировании, но зарезервировано при необходимости
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

String? createDriverAnnouncementError(AsyncValue<void> state) {
  return state.whenOrNull(
    error: (error, _) {
      if (error is ApiException) return error.message;
      return 'Не удалось сохранить объявление';
    },
  );
}
