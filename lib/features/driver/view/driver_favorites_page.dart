import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/providers/driver_favorites_provider.dart';
import 'package:fura24.kz/features/driver/utils/driver_order_actions.dart';
import 'package:fura24.kz/features/driver/utils/driver_verification_guard.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_order_card.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';
import 'package:fura24.kz/features/driver/providers/responded_orders_provider.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_order_detail_sheet.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_respond_sheet.dart';

class DriverFavoritesPage extends ConsumerWidget {
  const DriverFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(driverFavoritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SingleAppbar(title: tr('driver_favorites.title')),
      body: SafeArea(
        top: false,
        child: favoritesAsync.when(
          data: (orders) => _DriverFavoritesList(
            orders: orders,
            onRefresh: () async {
              await ref.refresh(driverFavoritesProvider.future);
            },
            onToggleFavorite: (order) =>
                toggleDriverOrderFavorite(context, ref, order),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                tr('driver_favorites.error'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverFavoritesList extends ConsumerWidget {
  const _DriverFavoritesList({
    required this.orders,
    required this.onRefresh,
    required this.onToggleFavorite,
  });

  final List<OrderSummary> orders;
  final Future<void> Function() onRefresh;
  final void Function(OrderSummary) onToggleFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final respondedOrders = ref.watch(respondedOrdersProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              children: [
                SizedBox(height: 120.h),
                Center(
                  child: Text(
                    tr('driver_favorites.empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 24.h + bottomInset),
              itemCount: orders.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final order = orders[index];
                return DriverOrderCard(
                  order: order,
                  isResponded:
                      order.hasResponded || respondedOrders.contains(order.id),
                  onTap: () => _openOrderDetail(context, order),
                  onRespond: () => _respondToOrder(context, ref, order),
                  onCall: order.canDriverCall
                      ? () => callOrderSender(context, order)
                      : null,
                  onWhatsApp: order.canDriverCall
                      ? () => openOrderWhatsApp(context, order)
                      : null,
                  onToggleFavorite: () => onToggleFavorite(order),
                );
              },
            ),
    );
  }

  Future<void> _respondToOrder(
    BuildContext context,
    WidgetRef ref,
    OrderSummary order,
  ) async {
    final allowed = await ensureDriverVerified(context, ref);
    if (!allowed) return;
    final messenger = ScaffoldMessenger.of(context);
    final responded = await showDriverRespondSheet(context, order);
    if (responded == true) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('driver_favorites.responded'))),
      );
    }
  }

  Future<void> _openOrderDetail(BuildContext context, OrderSummary order) {
    return showDriverOrderDetailSheet(context, order);
  }
}
