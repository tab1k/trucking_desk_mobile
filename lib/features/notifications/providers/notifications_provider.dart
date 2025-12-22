import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/notifications/data/notifications_repository.dart';
import 'package:fura24.kz/features/notifications/domain/app_notification.dart';

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, AsyncValue<List<AppNotification>>>(
  (ref) {
    final repository = ref.watch(notificationsRepositoryProvider);
    return NotificationsController(repository: repository);
  },
);

class NotificationsController
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsController({required this.repository})
    : super(const AsyncLoading()) {
    _load();
  }

  final NotificationsRepository repository;

  Future<void> _load() async {
    try {
      final items = await repository.fetchNotifications();
      state = AsyncData(items);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> refresh() => _load();

  Future<void> markAllAsRead() async {
    final current = state.valueOrNull ?? const [];
    final unreadIds = current.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;
    final updated = current.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
    state = AsyncData(updated);
    await repository.markAsRead(unreadIds);
  }

  Future<void> addAnnouncementNotification(DriverAnnouncement announcement) async {
    final notification = AppNotification(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Транспорт опубликован',
      body: '${announcement.departurePoint.cityName} → '
          '${announcement.destinationPoint.cityName} · ${announcement.vehicleTypeDisplay}',
      createdAt: DateTime.now(),
      isRead: false,
      entityId: announcement.id,
      type: 'driver_announcement_created',
      role: 'DRIVER',
    );
    final current = state.valueOrNull ?? const [];
    state = AsyncData([notification, ...current]);
    await repository.addNotification(notification);
  }

  Future<void> addNotification(AppNotification notification) async {
    final current = state.valueOrNull ?? const [];
    state = AsyncData([notification, ...current]);
    await repository.addNotification(notification);
  }

  Future<void> removeByEntity(String entityId) async {
    final current = state.valueOrNull ?? const [];
    final updated =
        current.where((n) => (n.entityId ?? '') != entityId).toList();
    state = AsyncData(updated);
    await repository.removeByEntity(entityId);
  }
}
