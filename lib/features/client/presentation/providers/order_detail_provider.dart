import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';

final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderDetail, String>((ref, orderId) async {
      final repository = ref.watch(orderRepositoryProvider);
      return await repository.fetchOrderDetail(orderId);
    });
