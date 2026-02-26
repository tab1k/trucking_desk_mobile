import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('my_cargo.bids.title'), // "Отклики"
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                tr(
                  'my_cargo.bids.order_number',
                  args: [orderId],
                ), // "Заказ TD-134"
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              backgroundImage:
                  info.driverPhoto != null && info.driverPhoto!.isNotEmpty
                  ? NetworkImage(info.driverPhoto!)
                  : null,
              child: info.driverPhoto != null && info.driverPhoto!.isNotEmpty
                  ? null
                  : Text(
                      _avatarLabel(info.driverName),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.driverName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (info.driverRating != null &&
                                info.driverRating! > 0) ...[
                              SizedBox(height: 4.h),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16.w,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    info.driverRating!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (info.amount != null)
                            Text(
                              '${_formatAmount(info.amount!)} ₸',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.push(
                            '/driver_reviews/${info.driverId}',
                            extra: {'driverName': info.driverName},
                          );
                        },
                        child: Text(
                          tr('driver_profile.reviews.title'),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(info.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
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

  static String _avatarLabel(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      final initials = (first + second).toUpperCase();
      if (!RegExp(r'[0-9]').hasMatch(initials)) {
        return initials;
      }
    }
    final trimmed = name.replaceAll(RegExp(r'[^A-Za-zА-Яа-я]'), '');
    if (trimmed.isEmpty) return 'ТК';
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
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
}
