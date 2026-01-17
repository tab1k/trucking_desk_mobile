import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';
import 'package:fura24.kz/features/client/presentation/providers/my_orders_provider.dart';
import 'package:fura24.kz/features/client/presentation/providers/order_detail_provider.dart';

Future<bool?> showClientBidDetailSheet(
  BuildContext context,
  OrderBidInfo bid, {
  required String orderId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) {
      final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: ClientBidDetailSheet(bid: bid, orderId: orderId),
      );
    },
  );
}

class ClientBidDetailSheet extends ConsumerStatefulWidget {
  const ClientBidDetailSheet({
    super.key,
    required this.bid,
    required this.orderId,
  });

  final OrderBidInfo bid;
  final String orderId;

  @override
  ConsumerState<ClientBidDetailSheet> createState() =>
      _ClientBidDetailSheetState();
}

class _ClientBidDetailSheetState extends ConsumerState<ClientBidDetailSheet> {
  bool _isProcessing = false;

  Future<void> _handleAction({required bool approve}) async {
    setState(() => _isProcessing = true);
    final repository = ref.read(orderRepositoryProvider);
    try {
      if (approve) {
        await repository.acceptBid(widget.bid.id);
      } else {
        await repository.rejectBid(widget.bid.id);
      }
      if (!mounted) return;
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? tr('my_cargo.bids.accepted')
                : tr('my_cargo.bids.declined'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('my_cargo.bids.error_process'))),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecide = widget.bid.status == 'PENDING';
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28.w,
                  backgroundColor: Colors.blueGrey.withValues(alpha: 0.15),
                  child: Text(
                    _initials(widget.bid.driverName),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.bid.driverName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (widget.bid.driverPhone.isNotEmpty)
                        Text(
                          widget.bid.driverPhone,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  splashRadius: 20.w,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            if (widget.bid.amount != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('my_cargo.bids.offer'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          _formatAmount(widget.bid.amount!),
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black.withValues(alpha: 0.8),
                              ),
                          _formatDateTime(widget.bid.createdAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (widget.bid.comment.isNotEmpty) ...[
              SizedBox(height: 18.h),
              Text(
                tr('my_cargo.bids.comment'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(widget.bid.comment),
              ),
            ],
            if (canDecide) ...[
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _handleAction(approve: false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                          horizontal: 16.w,
                        ),
                        side: BorderSide(
                          color: const Color(0xFFE53935),
                          width: 1.2,
                        ),
                        foregroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),

                      label: Text(
                        tr('my_cargo.bids.actions.decline'),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _handleAction(approve: true),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                          horizontal: 16.w,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 1,
                      ),

                      label: Text(
                        _isProcessing
                            ? tr('my_cargo.bids.actions.processing')
                            : tr('my_cargo.bids.actions.accept'),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        tr(
                          'order_detail.labels.status',
                          args: [
                            _statusLabel(
                              widget.bid.status,
                              widget.bid.statusLabel,
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
  }

  String _formatAmount(double amount) {
    final isInt = amount == amount.roundToDouble();
    return isInt ? amount.toStringAsFixed(0) : amount.toStringAsFixed(1);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return tr('my_cargo.bids.date_unknown');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} · $hour:$minute';
  }

  String _statusLabel(String status, String raw) {
    if (raw.isNotEmpty) return raw;
    final key = () {
      switch (status) {
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
        default:
          return '';
      }
    }();
    if (key.isEmpty) return status;
    final translated = tr(key);
    return translated == key ? status : translated;
  }
}
