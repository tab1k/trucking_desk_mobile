import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/auth/repositories/auth_storage.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/providers/profile/profile_provider.dart';

final myOrdersProvider = FutureProvider.autoDispose<List<OrderSummary>>((
  ref,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  String? userId;
  if (currentUser != null) {
    userId = currentUser.id.toString();
  } else {
    final session = await ref.read(authStorageProvider).readSession();
    userId = session?.user.id.toString();
  }

  final orders = await repository.fetchOrders();
  if (userId == null) {
    return orders;
  }

  return orders.where((order) => order.senderId == userId).toList();
});
