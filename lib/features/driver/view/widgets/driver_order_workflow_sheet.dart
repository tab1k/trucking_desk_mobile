import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';
import 'package:fura24.kz/features/client/presentation/providers/order_detail_provider.dart';
import 'package:fura24.kz/features/driver/providers/driver_assigned_orders_provider.dart';

Future<void> showDriverOrderWorkflowSheet(
  BuildContext context,
  String orderId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _DriverOrderWorkflowSheet(orderId: orderId),
  );
}

class _DriverOrderWorkflowSheet extends ConsumerStatefulWidget {
  const _DriverOrderWorkflowSheet({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_DriverOrderWorkflowSheet> createState() =>
      _DriverOrderWorkflowSheetState();
}

class _DriverOrderWorkflowSheetState
    extends ConsumerState<_DriverOrderWorkflowSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(orderDetailProvider(widget.orderId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: detailAsync.when(
        data: (detail) => _OrderContent(
          detail: detail,
          isProcessing: _isProcessing,
          onAction: _handleAction,
          safeBottom: safeBottom,
        ),
        loading:
            () => SizedBox(
              height: 240.h,
              child: const Center(child: CircularProgressIndicator()),
            ),
        error: (error, _) => SizedBox(
          height: 220.h,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                'Не удалось загрузить заказ. Попробуйте позже.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    Future<void> Function(OrderRepository repo) performer,
    String successMessage,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await performer(repo);
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(driverAssignedOrdersProvider);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось выполнить действие')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _OrderContent extends ConsumerWidget {
  const _OrderContent({
    required this.detail,
    required this.isProcessing,
    required this.onAction,
    required this.safeBottom,
  });

  final OrderDetail detail;
  final bool isProcessing;
  final Future<void> Function(
    Future<void> Function(OrderRepository repo),
    String successMessage,
  ) onAction;
  final double safeBottom;

  static const List<String> _timelineStatuses = [
    'WAITING_DRIVER_CONFIRMATION',
    'ACCEPTED',
    'READY_FOR_PICKUP',
    'WAITING_PICKUP_CONFIRMATION',
    'IN_PROGRESS',
    'WAITING_DELIVERY_CONFIRMATION',
    'DELIVERED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    OrderBidInfo? pendingBid;
    for (final bid in detail.bids) {
      if (bid.status == 'WAITING_DRIVER_DECISION') {
        pendingBid = bid;
        break;
      }
    }
    pendingBid ??= detail.bids.isNotEmpty ? detail.bids.first : null;
    final hasOwnBid = pendingBid != null;
    final isAssignedDriver = detail.driverId?.isNotEmpty ?? false;
    final actions = _buildActions(
      hasOwnBid: hasOwnBid,
      pendingBid: pendingBid,
      isAssignedDriver: isAssignedDriver,
    );
    final canShareLocation =
        (detail.driverId?.isNotEmpty ?? false) &&
        !detail.isFinished &&
        detail.status == 'IN_PROGRESS';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + safeBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            detail.cargoName.isEmpty ? 'Без названия' : detail.cargoName,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${detail.departurePoint.cityName} → ${detail.destinationPoint.cityName}',
            style: TextStyle(fontSize: 15.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 10.h),
          _InfoRow(label: 'Оплата', value: '${detail.amount} ${detail.currency}'),
          _InfoRow(
            label: 'Статус',
            value: _statusLabel(detail.status),
          ),
          SizedBox(height: 6.h),
          if (detail.description != null && detail.description!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Комментарий:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  detail.description!,
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Статус рейса',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          _StatusTimeline(
            steps: _timelineStatuses,
            currentStatus: detail.status,
            showShareLocationAction: canShareLocation,
            onShareLocation:
                canShareLocation ? () => _sendLocation(detail.id) : null,
          ),

          if (actions.isNotEmpty) ...[
            SizedBox(height: 16.h),

            SizedBox(height: 12.h),
            ...actions.map(
              (config) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _DriverActionButton(
                  config: config,
                  disabled: isProcessing,
                ),
              ),
            ),
          ],
          
        ],
      ),
    );
  }

  List<_DriverActionConfig> _buildActions({
    required bool hasOwnBid,
    required OrderBidInfo? pendingBid,
    required bool isAssignedDriver,
  }) {
    final actions = <_DriverActionConfig>[];
    if (!detail.isFinished && hasOwnBid) {
      final canDecideBid =
          pendingBid != null &&
          pendingBid.status == 'WAITING_DRIVER_DECISION' &&
          (detail.status == 'WAITING_DRIVER_CONFIRMATION' ||
              detail.status == 'WAITING_DRIVER_DECISION');
      if (canDecideBid) {
        actions.add(
          _DriverActionConfig(
            label: 'Подтвердить участие',
            onPressed: () => onAction(
              (repo) => repo.confirmDriverBid(pendingBid.id),
              'Вы подтвердили заказ',
            ),
          ),
        );
        actions.add(
          _DriverActionConfig(
            label: 'Отказаться от заказа',
            style: _DriverActionStyle.secondary,
            onPressed: () => onAction(
              (repo) => repo.declineDriverBid(pendingBid.id),
              'Вы отказались от заказа',
            ),
          ),
        );
      }
    }

    if (!detail.isFinished && isAssignedDriver) {
      final awaitingDecision =
          pendingBid != null &&
          pendingBid.status == 'WAITING_DRIVER_DECISION' &&
          (detail.status == 'WAITING_DRIVER_CONFIRMATION' ||
              detail.status == 'WAITING_DRIVER_DECISION');

      if (!detail.pickupConfirmedByDriver &&
          (detail.status == 'READY_FOR_PICKUP' ||
              detail.status == 'WAITING_PICKUP_CONFIRMATION')) {
        actions.add(
          _DriverActionConfig(
            label: 'Забрал груз',
            onPressed: () => onAction(
              (repo) => repo.markDriverPickedUp(detail.id),
              'Груз отмечен как забранный',
            ),
          ),
        );
      }
      if (!detail.pickupConfirmedByDriver &&
          detail.status == 'ACCEPTED') {
        actions.add(
          _DriverActionConfig(
            label: 'На месте погрузки',
            onPressed: () => onAction(
              (repo) => repo.markDriverReady(detail.id),
              'Статус обновлён',
            ),
          ),
        );
      }
      if (!detail.deliveryConfirmedByDriver &&
          (detail.status == 'IN_PROGRESS' ||
              detail.status == 'WAITING_DELIVERY_CONFIRMATION')) {
        actions.add(
          _DriverActionConfig(
            label: 'Доставил груз',
            onPressed: () => onAction(
              (repo) => repo.markDriverDelivered(detail.id),
              'Доставка отмечена',
            ),
          ),
        );
      }
      final canCancel =
          !detail.pickupConfirmedByDriver &&
          !awaitingDecision &&
          detail.status != 'IN_PROGRESS' &&
          detail.status != 'WAITING_DELIVERY_CONFIRMATION' &&
          detail.status != 'DELIVERED';
      if (canCancel) {
        actions.add(
          _DriverActionConfig(
            label: 'Отказаться от заказа',
            style: _DriverActionStyle.secondary,
            onPressed: () => onAction(
              (repo) => repo.releaseDriver(detail.id),
              'Вы снялись с заказа',
            ),
          ),
        );
      }
    }

    return actions;
  }

  Future<void> _sendLocation(String orderId) async {
    return onAction((repo) async {
      final position = await _determinePosition();
      await repo.submitDriverLocation(
        orderId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }, 'Геолокация обновлена');
  }

  Future<Position> _determinePosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw ApiException('Включите службы геолокации');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiException('Нет доступа к геолокации');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  List<Widget> _historyTiles(OrderDetail detail) {
    if (detail.statusHistory.isEmpty) {
      return [
        _HistoryTile(
          label: 'История ещё не сформирована',
          value: '',
        ),
      ];
    }
    return detail.statusHistory.take(6).map((entry) {
      final display =
          entry.statusDisplay.isEmpty
              ? _statusLabel(entry.status)
              : entry.statusDisplay;
      final date = entry.createdAt != null ? _formatDateTime(entry.createdAt!) : '';
      return _HistoryTile(
        label: display,
        value: date,
        subtitle: entry.actorName,
      );
    }).toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'WAITING_DRIVER_CONFIRMATION':
        return 'Ждёт подтверждения водителя';
      case 'ACCEPTED':
        return 'Водитель назначен';
      case 'READY_FOR_PICKUP':
        return 'На месте погрузки';
      case 'WAITING_PICKUP_CONFIRMATION':
        return 'Ждет подтверждения передачи';
      case 'IN_PROGRESS':
        return 'В пути';
      case 'WAITING_DELIVERY_CONFIRMATION':
        return 'Ожидает подтверждения доставки';
      case 'DELIVERED':
        return 'Доставлен';
      case 'CANCELLED':
        return 'Отменен';
      default:
        return 'Новый';
    }
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} · $hour:$minute';
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({
    required this.steps,
    required this.currentStatus,
    this.showShareLocationAction = false,
    this.onShareLocation,
  });

  final List<String> steps;
  final String currentStatus;
  final bool showShareLocationAction;
  final VoidCallback? onShareLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var index = steps.indexOf(currentStatus);
    if (index < 0) {
      index = 0;
    }
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            label: _displayLabel(steps[i]),
            isActive: i == index,
            isPassed: i < index,
            isLast: i == steps.length - 1,
            color: theme.colorScheme.primary,
            showAction:
                showShareLocationAction &&
                steps[i] == 'IN_PROGRESS' &&
                onShareLocation != null,
            onAction: onShareLocation,
          ),
      ],
    );
  }

  String _displayLabel(String status) {
    switch (status) {
      case 'WAITING_DRIVER_CONFIRMATION':
        return 'Ожидает подтверждения';
      case 'ACCEPTED':
        return 'Водитель назначен';
      case 'READY_FOR_PICKUP':
        return 'На месте погрузки';
      case 'WAITING_PICKUP_CONFIRMATION':
        return 'Ожидает передачи';
      case 'IN_PROGRESS':
        return 'В пути';
      case 'WAITING_DELIVERY_CONFIRMATION':
        return 'Ожидает подтверждения доставки';
      case 'DELIVERED':
        return 'Доставлен';
      default:
        return status;
    }
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isActive,
    required this.isPassed,
    required this.isLast,
    required this.color,
    this.showAction = false,
    this.onAction,
  });

  final String label;
  final bool isActive;
  final bool isPassed;
  final bool isLast;
  final Color color;
  final bool showAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final dotSize = isActive ? 16.w : 12.w;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isActive
                        ? color
                        : isPassed
                            ? color.withValues(alpha: 0.4)
                            : Colors.white,
                border: Border.all(
                  color: isActive || isPassed
                      ? color
                      : Colors.grey.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 28.h,
                color:
                    isPassed
                        ? color.withValues(alpha: 0.6)
                        : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isActive
                              ? color
                              : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                if (showAction)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Отправить локацию',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.label, required this.value, this.subtitle = ''});

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: value.isNotEmpty ? Text(value, style: const TextStyle(fontSize: 12)) : null,
    );
  }
}

class _DriverActionButton extends StatelessWidget {
  const _DriverActionButton({required this.config, required this.disabled});

  final _DriverActionConfig config;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = config.style == _DriverActionStyle.primary;
    final backgroundColor =
        isPrimary
            ? theme.colorScheme.primary
            : Colors.white;
    final foregroundColor =
        isPrimary
            ? Colors.white
            : theme.colorScheme.primary;
    final borderColor =
        isPrimary
            ? Colors.transparent
            : theme.colorScheme.primary.withValues(alpha: 0.4);

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        elevation: isPrimary ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: disabled ? null : config.onPressed,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  config.label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverActionConfig {
  const _DriverActionConfig({
    required this.label,
    required this.onPressed,
    this.style = _DriverActionStyle.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final _DriverActionStyle style;
}

enum _DriverActionStyle { primary, secondary }
