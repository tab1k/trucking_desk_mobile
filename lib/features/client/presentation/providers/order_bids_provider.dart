import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';

final orderBidsProvider = FutureProvider.autoDispose
    .family<List<OrderBidInfo>, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchOrderBids(orderId: orderId);
});
