import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';

final driverFavoritesProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchDriverFavoriteOrders();
});
