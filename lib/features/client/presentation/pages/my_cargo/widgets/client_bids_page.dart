import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/widgets/client_bid_detail_page.dart';
import 'package:fura24.kz/features/client/presentation/providers/order_bids_provider.dart';

class ClientBidsPage extends ConsumerWidget {
  const ClientBidsPage({
    super.key,
    required this.orderId,
    required this.orderTitle,
  });

  final String orderId;
  final String orderTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(orderBidsProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: Text(tr('my_cargo.bids.title'))),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('my_cargo.bids.order_number', args: [orderId]),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4.h),
              Text(
                orderTitle,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: bidsAsync.when(
                  data: (bids) => bids.isEmpty
                      ? const _EmptyBidsState()
                      : ListView.separated(
                          itemCount: bids.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (_, index) => _BidTile(
                            info: bids[index],
                            orderId: orderId,
                            onUpdated: () =>
                                ref.invalidate(orderBidsProvider(orderId)),
                          ),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      _BidsErrorState(message: error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBidsState extends StatelessWidget {
  const _EmptyBidsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48.w, color: Colors.grey[400]),
          SizedBox(height: 12.h),
          Text(
            tr('my_cargo.bids.empty'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            tr('my_cargo.bids.empty_subtitle'),
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BidsErrorState extends StatelessWidget {
  const _BidsErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red[400]),
        ),
      ),
    );
  }
}

class _BidTile extends StatelessWidget {
  const _BidTile({required this.info, required this.orderId, this.onUpdated});

  final OrderBidInfo info;
  final String orderId;
  final VoidCallback? onUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _avatarColor(info.driverId);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () async {
        final updated = await showClientBidDetailSheet(
          context,
          info,
          orderId: orderId,
        );
        if (updated == true) {
          onUpdated?.call();
        }
      },
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22.w,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Text(
                _avatarLabel(info.driverId),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          info.driverName,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _BidStatusChip(label: _bidStatusLabel(info)),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  if (info.amount != null)
                    Text(
                      tr(
                        'my_cargo.bids.offer_amount',
                        args: [_formatAmount(info.amount!)],
                      ),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (info.comment.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      info.comment,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Text(
                    _formatDate(info.createdAt),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _avatarColor(String seed) {
    final colors = Colors.primaries;
    if (seed.isEmpty) return Colors.blueGrey;
    final index = seed.hashCode.abs() % colors.length;
    return colors[index];
  }

  static String _avatarLabel(String value) {
    if (value.isEmpty) return '?';
    final trimmed = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (trimmed.length >= 2) {
      return trimmed.substring(trimmed.length - 2).toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  String _formatAmount(double amount) {
    final isInt = amount == amount.roundToDouble();
    return isInt ? amount.toStringAsFixed(0) : amount.toStringAsFixed(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return tr('my_cargo.bids.date_unknown');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _bidStatusLabel(OrderBidInfo info) {
    if (info.statusLabel.isNotEmpty) return info.statusLabel;
    final key = () {
      switch (info.status) {
        case 'PENDING':
          return 'my_cargo.bids.status.new';
        case 'WAITING_DRIVER_DECISION':
        case 'CONFIRMED':
          return 'my_cargo.bids.status.confirmed';
        case 'DECLINED':
          return 'my_cargo.bids.status.declined';
        case 'CANCELLED':
        case 'REJECTED':
          return 'my_cargo.bids.status.cancelled';
        case 'DRIVER_DECLINED':
          return 'my_cargo.bids.status.driver_declined';
        default:
          return '';
      }
    }();
    if (key.isEmpty) return info.status;
    final translated = tr(key);
    return translated == key ? info.status : translated;
  }
}

class _BidStatusChip extends StatelessWidget {
  const _BidStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E88E5),
        ),
      ),
    );
  }
}
