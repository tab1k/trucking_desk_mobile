import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fura24.kz/features/client/data/repositories/driver_announcement_repository.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';

/// Провайдер объявлений текущего водителя.
///
/// Бэкенд возвращает только объявления авторизованного водителя, поэтому
/// дополнительных фильтров не требуется.
final driverMyAnnouncementsProvider =
    FutureProvider.autoDispose<List<DriverAnnouncement>>((ref) async {
      final repository = ref.watch(driverAnnouncementRepositoryProvider);
      return repository.fetchAnnouncements();
    });
