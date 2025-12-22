import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';

final driverAssignedOrdersProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  String? driverId;
  if (currentUser != null) {
    driverId = currentUser.id.toString();
  } else {
    final session = await ref.read(authStorageProvider).readSession();
    driverId = session?.user.id.toString();
  }

  if (driverId == null) {
    return const [];
  }

  final orders = await repository.fetchOrders();
  return orders.where((order) => order.driverId == driverId).toList();
});
