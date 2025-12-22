import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/domain/models/driver_cargo_filters.dart';

final driverAvailableOrdersProvider = FutureProvider.autoDispose
    .family<List<OrderSummary>, DriverCargoFilters>((ref, filters) async {
  final repository = ref.watch(orderRepositoryProvider);
  final params = filters.toQueryParameters();
  return repository.fetchAvailableOrders(filters: params.isEmpty ? null : params);
});
