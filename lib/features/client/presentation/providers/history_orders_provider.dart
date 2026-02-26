import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/history_filter.dart';
import 'package:fura24.kz/features/client/domain/models/history_status.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';

final historyFilterProvider = StateProvider.autoDispose<HistoryFilter>((ref) {
  return const HistoryFilter();
});

final historyOrdersProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final filter = ref.watch(historyFilterProvider);

  String? userId;
  if (currentUser != null) {
    userId = currentUser.id.toString();
  } else {
    final session = await ref.read(authStorageProvider).readSession();
    userId = session?.user.id.toString();
  }

  if (userId == null) {
    return [];
  }

  final apiFilters = <String, dynamic>{'sender': userId};

  // Status Filter
  if (filter.status == HistoryStatus.completed) {
    apiFilters['status'] = 'DELIVERED';
  } else if (filter.status == HistoryStatus.cancelled) {
    apiFilters['status'] = 'CANCELLED';
  } else {
    // HistoryStatus.all -> Both Completed and Cancelled
    apiFilters['status__in'] = 'DELIVERED,CANCELLED';
  }

  // Date Filter
  if (filter.dateRange != null) {
    final start = filter.dateRange!.start.toIso8601String().split('T').first;
    final end = filter.dateRange!.end.toIso8601String().split('T').first;
    // Filtering by created_at (or transportation_date depending on requirement)
    // Usually history is about when order was created or completed. Let's use created_at for generic history lookup.
    apiFilters['created_at__gte'] = start;
    apiFilters['created_at__lte'] = end;
  }

  // Search Filter
  if (filter.searchQuery.isNotEmpty) {
    apiFilters['search'] = filter.searchQuery;
  }

  return repository.fetchOrders(filters: apiFilters);
});
