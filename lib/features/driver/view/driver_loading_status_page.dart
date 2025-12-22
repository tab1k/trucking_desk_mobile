import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/providers/driver_assigned_orders_provider.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_order_workflow_sheet.dart';

const Set<String> _relevantStatuses = {
  'WAITING_DRIVER_CONFIRMATION',
  'WAITING_DRIVER_DECISION',
  'ACCEPTED',
  'READY_FOR_PICKUP',
  'WAITING_PICKUP_CONFIRMATION',
  'IN_PROGRESS',
  'WAITING_DELIVERY_CONFIRMATION',
};

class DriverLoadingStatusPage extends ConsumerStatefulWidget {
  const DriverLoadingStatusPage({super.key});

  @override
  ConsumerState<DriverLoadingStatusPage> createState() =>
      _DriverLoadingStatusPageState();
}

class _DriverLoadingStatusPageState
    extends ConsumerState<DriverLoadingStatusPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.refresh(driverAssignedOrdersProvider));
  }

  Future<void> _refresh() {
    return ref.refresh(driverAssignedOrdersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(driverAssignedOrdersProvider);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          toolbarHeight: 60.h,
          leading: Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: Material(
              color: Colors.grey[200],
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: Colors.black87,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              tr('driver_loading.title'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ordersAsync.when(
              data: (orders) {
                final filtered = orders
                    .where((o) => _relevantStatuses.contains(o.rawStatus))
                    .toList();
                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120.h),
                      _EmptyState(),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, index) =>
                      _StatusCard(order: filtered[index]),
                );
              },
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 120.h),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        tr('driver_loading.error'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});
  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _statusInfo(order.rawStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () => showDriverOrderWorkflowSheet(context, order.id),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'TD-${order.id}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusPill(label: status.label, color: status.color),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.routeLabel,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${tr('driver_loading.date')}: ${order.dateLabel}',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                _PriceSection(
                  price: order.priceLabel,
                  paymentType: order.paymentTypeLabel,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.vehicleTypeLabel,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${order.loadingTypeLabel} · ${order.weightLabel} · ${order.volumeLabel}',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 18.w,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    order.senderName.isNotEmpty
                        ? order.senderName.characters.first
                        : '',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.senderName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        order.cargoName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => showDriverOrderWorkflowSheet(context, order.id),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(tr('driver_loading.open')),
                ),
              ],
            ),
            if (status.note.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  status.note,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: Colors.black.withValues(alpha: 0.7),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(String rawStatus) {
    switch (rawStatus) {
      case 'WAITING_DRIVER_CONFIRMATION':
        return _StatusInfo(
          label: tr('driver_loading.status.waiting_you'),
          color: const Color(0xFFFFA000),
          note: tr('driver_loading.notes.waiting_you'),
        );
      case 'WAITING_DRIVER_DECISION':
        return _StatusInfo(
          label: tr('driver_loading.status.need_answer'),
          color: const Color(0xFFFFA000),
          note: tr('driver_loading.notes.need_answer'),
        );
      case 'READY_FOR_PICKUP':
        return _StatusInfo(
          label: tr('driver_loading.status.to_pickup'),
          color: const Color(0xFF00B2FF),
          note: tr('driver_loading.notes.to_pickup'),
        );
      case 'ACCEPTED':
        return _StatusInfo(
          label: tr('driver_loading.status.accepted'),
          color: const Color(0xFF2EB872),
          note: tr('driver_loading.notes.accepted'),
        );
      case 'WAITING_PICKUP_CONFIRMATION':
        return _StatusInfo(
          label: tr('driver_loading.status.wait_pickup'),
          color: const Color(0xFF1E88E5),
          note: tr('driver_loading.notes.wait_pickup'),
        );
      case 'IN_PROGRESS':
        return _StatusInfo(
          label: tr('driver_loading.status.in_progress'),
          color: const Color(0xFF2EB872),
          note: tr('driver_loading.notes.in_progress'),
        );
      case 'WAITING_DELIVERY_CONFIRMATION':
        return _StatusInfo(
          label: tr('driver_loading.status.wait_delivery'),
          color: const Color(0xFF1E88E5),
          note: tr('driver_loading.notes.wait_delivery'),
        );
      default:
        return _StatusInfo(
          label: tr('driver_loading.status.active'),
          color: const Color(0xFF78909C),
          note: tr('driver_loading.notes.active'),
        );
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 56.w, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            Text(
              tr('driver_loading.empty.title'),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              tr('driver_loading.empty.subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.price, required this.paymentType});
  final String price;
  final String paymentType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayPrice =
        price.isEmpty || price == '—' ? tr('driver_loading.price_on_request') : price;
    final displayPayment =
        paymentType.isEmpty || paymentType == '—' ? tr('driver_loading.payment_per_trip') : paymentType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          displayPrice,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          displayPayment,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _StatusInfo {
  const _StatusInfo({
    required this.label,
    required this.color,
    required this.note,
  });

  final String label;
  final Color color;
  final String note;
}
