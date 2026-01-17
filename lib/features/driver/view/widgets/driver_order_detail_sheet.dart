import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_photo_viewer.dart';

Future<void> showDriverOrderDetailSheet(
  BuildContext context,
  OrderSummary order,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _DriverOrderDetailSheet(order: order),
  );
}

class _DriverOrderDetailSheet extends StatelessWidget {
  const _DriverOrderDetailSheet({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomInset + safeBottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              order.cargoName,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _buildFullRoute(order),
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            ),
            if (order.photoUrls.isNotEmpty) ...[
              SizedBox(height: 16.h),
              SizedBox(
                height: 120.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.photoUrls.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12.w),
                  itemBuilder: (_, index) {
                    final url = order.photoUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: InkWell(
                        onTap: () => showDriverPhotoViewer(
                          context,
                          order.photoUrls,
                          initialIndex: index,
                        ),
                        child: Container(
                          width: 160.w,
                          color: Colors.grey[200],
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            SizedBox(height: 20.h),
            _InfoBlock(
              title: tr('driver_order_detail.cargo_params'),
              children: [
                _InfoRow(
                  label: tr('driver_order_detail.weight'),
                  value: order.weightLabel,
                ),
                _InfoRow(
                  label: tr('driver_order_detail.volume'),
                  value: order.volumeLabel,
                ),
                _InfoRow(
                  label: tr('driver_order_detail.vehicle_type'),
                  value: order.vehicleTypeLabel,
                ),
                _InfoRow(
                  label: tr('driver_order_detail.loading_type'),
                  value: order.loadingTypeLabel,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _InfoBlock(
              title: tr('driver_order_detail.cost_and_terms'),
              children: [
                _InfoRow(
                  label: tr('driver_order_detail.amount'),
                  value: order.priceLabel,
                ),
                _InfoRow(
                  label: tr('driver_order_detail.payment'),
                  value: order.paymentTypeLabel,
                ),
                _InfoRow(
                  label: tr('driver_order_detail.status'),
                  value: _statusLabel(order.status),
                ),
                _InfoRow(
                  label: tr('driver_order_detail.departure_date'),
                  value: order.dateLabel,
                ),
              ],
            ),
            if (order.description.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                tr('driver_order_detail.sender_comment'),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Text(
                order.description,
                style: TextStyle(fontSize: 13.sp, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return tr('driver_order_detail.status_pending');
      case CargoStatus.inTransit:
        return tr('driver_order_detail.status_in_transit');
      case CargoStatus.completed:
        return tr('driver_order_detail.status_completed');
      case CargoStatus.cancelled:
        return tr('driver_order_detail.status_cancelled');
    }
  }

  String _buildFullRoute(OrderSummary order) {
    if (order.waypoints.isNotEmpty) {
      final cities = order.waypoints
          .map((w) => w.location['city_name'] as String? ?? '')
          .where((c) => c.isNotEmpty)
          .toList();
      if (cities.length >= 2) {
        return cities.join(' → ');
      }
    }
    return '${order.departureCity} → ${order.destinationCity}';
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
