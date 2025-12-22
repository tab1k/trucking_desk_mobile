import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/client/data/repositories/driver_announcement_repository.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement_filters.dart';

final driverAnnouncementFiltersProvider = StateNotifierProvider<
    DriverAnnouncementFiltersNotifier, DriverAnnouncementFilters>(
  (ref) => DriverAnnouncementFiltersNotifier(),
);

final driverAnnouncementsProvider =
    FutureProvider.autoDispose<List<DriverAnnouncement>>((ref) async {
      final repository = ref.watch(driverAnnouncementRepositoryProvider);
      final filters = ref.watch(driverAnnouncementFiltersProvider);
      return repository.fetchAnnouncements(filters: filters);
    });

final favoriteDriverAnnouncementsProvider =
    FutureProvider.autoDispose<List<DriverAnnouncement>>((ref) async {
      final repository = ref.watch(driverAnnouncementRepositoryProvider);
      return repository.fetchFavoriteAnnouncements();
    });

class DriverAnnouncementFiltersNotifier
    extends StateNotifier<DriverAnnouncementFilters> {
  DriverAnnouncementFiltersNotifier() : super(const DriverAnnouncementFilters());

  void updateFilters(DriverAnnouncementFilters filters) {
    state = filters;
  }

  void reset() {
    state = const DriverAnnouncementFilters();
  }
}
