import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:characters/characters.dart';

import 'package:fura24.kz/features/client/domain/models/order_summary.dart';

class DriverOrderCard extends StatelessWidget {
  const DriverOrderCard({
    super.key,
    required this.order,
    required this.onRespond,
    required this.onToggleFavorite,
    this.onCall,
    this.onWhatsApp,
    this.onTap,
    this.isResponded = false,
  });

  final OrderSummary order;
  final VoidCallback onRespond;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onTap;
  final bool isResponded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
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
                        order.cargoName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        order.routeLabel,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${tr('driver_orders.card.departure')}: ${order.dateLabel}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    order.isFavoriteForDriver
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: order.isFavoriteForDriver
                        ? const Color(0xFFE53935)
                        : Colors.black45,
                  ),
                  onPressed: onToggleFavorite,
                  tooltip: order.isFavoriteForDriver
                      ? tr('driver_orders.card.unfavorite')
                      : tr('driver_orders.card.favorite'),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _DriverInfoChip(
                  icon: Icons.local_shipping_outlined,
                  label: order.vehicleTypeLabel,
                ),
                _DriverInfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: order.loadingTypeLabel,
                ),
                _DriverInfoChip(
                  icon: Icons.payments_outlined,
                  label: order.paymentTypeLabel,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                _DriverSpecItem(
                  iconPath: 'assets/svg/wei.svg',
                  label: order.weightLabel,
                ),
                SizedBox(width: 18.w),
                _DriverSpecItem(
                  iconPath: 'assets/svg/ruler.svg',
                  label: order.volumeLabel,
                ),
                const Spacer(),
                Text(
                  order.priceLabel,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (order.description.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  order.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
            SizedBox(height: 14.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 16.w,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  backgroundImage: order.senderAvatarUrl != null
                      ? NetworkImage(order.senderAvatarUrl!)
                      : null,
                  child: order.senderAvatarUrl == null
                      ? Text(
                          order.senderName.isNotEmpty
                              ? order.senderName.characters.first
                              : '',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    order.senderName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isResponded ? null : onRespond,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      disabledBackgroundColor: theme.colorScheme.primary
                          .withOpacity(0.35),
                      backgroundColor: isResponded
                          ? theme.colorScheme.primary.withOpacity(0.85)
                          : null,
                    ),
                    child: Text(
                      isResponded
                          ? tr('driver_orders.card.responded')
                          : tr('driver_orders.card.respond'),
                    ),
                  ),
                ),
                if (onWhatsApp != null) ...[
                  SizedBox(width: 8.w),
                  Material(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/svg/whatsapp.svg',
                        width: 24.w,
                        height: 24.w,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF25D366),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: onWhatsApp,
                    ),
                  ),
                ],
                if (onCall != null) ...[
                  SizedBox(width: 8.w),
                  Material(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    child: IconButton(
                      icon: Icon(Icons.phone, color: theme.colorScheme.primary),
                      onPressed: onCall,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return const Color(0xFF00C968);
      case CargoStatus.inTransit:
        return const Color(0xFFFF6B00);
      case CargoStatus.completed:
        return const Color(0xFF64B5F6);
      case CargoStatus.cancelled:
        return const Color(0xFFFF4757);
    }
  }

  String _statusLabel(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return 'Ожидание';
      case CargoStatus.inTransit:
        return 'В пути';
      case CargoStatus.completed:
        return 'Завершен';
      case CargoStatus.cancelled:
        return 'Отменен';
    }
  }
}

class _DriverSpecItem extends StatelessWidget {
  const _DriverSpecItem({required this.iconPath, required this.label});

  final String iconPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 18.w,
          height: 18.w,
          colorFilter: const ColorFilter.mode(
            Color(0xFF64B5F6),
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DriverInfoChip extends StatelessWidget {
  const _DriverInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: Colors.black54),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
