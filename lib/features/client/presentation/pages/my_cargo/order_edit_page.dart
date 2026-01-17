import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/create_order_page.dart';
import 'package:fura24.kz/features/client/presentation/providers/order_detail_provider.dart';

class OrderEditPage extends ConsumerWidget {
  const OrderEditPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return orderAsync.when(
      data: (detail) => CreateOrderPage(editingOrder: detail),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(tr('my_cargo.edit_title'))),
        body: Center(
          child: Text(
            error is Exception
                ? error.toString()
                : tr('my_cargo.error.load_single'),
          ),
        ),
      ),
    );
  }
}
