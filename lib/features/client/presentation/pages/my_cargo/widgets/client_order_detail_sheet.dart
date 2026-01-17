import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';
import 'package:fura24.kz/features/client/presentation/providers/my_orders_provider.dart';
import 'package:fura24.kz/features/client/presentation/providers/order_detail_provider.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_photo_viewer.dart';
import 'package:fura24.kz/features/reviews/view/rating_bottom_sheet.dart';

Future<void> showClientOrderDetailSheet(BuildContext context, String orderId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: ClientOrderDetailSheet(orderId: orderId),
    ),
  );
}

class ClientOrderDetailSheet extends ConsumerStatefulWidget {
  const ClientOrderDetailSheet({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ClientOrderDetailSheet> createState() =>
      _ClientOrderDetailSheetState();
}

class _ClientOrderDetailSheetState
    extends ConsumerState<ClientOrderDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Refresh summary list so statuses on cards stay in sync with details.
    Future.microtask(() => ref.invalidate(myOrdersProvider));
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(orderDetailProvider(widget.orderId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return detailAsync.when(
      data: (detail) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          16.h,
          20.w,
          bottomInset + safeBottom + 12.h,
        ),
        child: _OrderDetailContent(orderId: widget.orderId, detail: detail),
      ),
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Center(
          child: Text(
            tr('my_cargo.error.load_detail'),
            style: TextStyle(color: Colors.red[400]),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _OrderDetailContent extends ConsumerStatefulWidget {
  const _OrderDetailContent({required this.orderId, required this.detail});

  final String orderId;
  final OrderDetail detail;

  @override
  ConsumerState<_OrderDetailContent> createState() =>
      _OrderDetailContentState();
}

class _OrderDetailContentState extends ConsumerState<_OrderDetailContent> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
        SizedBox(height: 12.h),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _pageIndex = index),
            children: [
              _PrimaryInfoPage(orderId: widget.orderId, detail: widget.detail),
              _SecondaryInfoPage(detail: widget.detail),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = index == _pageIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: isActive ? 22.w : 8.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PrimaryInfoPage extends StatelessWidget {
  const _PrimaryInfoPage({required this.orderId, required this.detail});

  final String orderId;
  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.cargoName.isEmpty
                ? tr('order_detail.sections.listing')
                : detail.cargoName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            detail.waypoints.isNotEmpty
                ? detail.waypoints.map((w) => w.location.cityName).join(' → ')
                : '${detail.departurePoint.cityName} → ${detail.destinationPoint.cityName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: [
              _Chip(label: _vehicleLabel(detail.vehicleType)),
              _Chip(label: _loadingLabel(detail.loadingType)),
              if (detail.paymentType.isNotEmpty)
                _Chip(label: _paymentLabel(detail)),
            ],
          ),
          if (detail.photoUrls.isNotEmpty) ...[
            SizedBox(height: 18.h),
            Text(
              tr('order_detail.photos'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 120.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: detail.photoUrls.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, index) {
                  final url = detail.photoUrls[index];
                  return _PhotoThumbnail(
                    url: url,
                    onTap: () => showDriverPhotoViewer(
                      context,
                      detail.photoUrls,
                      initialIndex: index,
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 20.h),
          _OrderStatusSection(orderId: orderId, detail: detail),
          SizedBox(height: 20.h),
          _BidList(detail: detail),
        ],
      ),
    );
  }
}

class _SecondaryInfoPage extends StatelessWidget {
  const _SecondaryInfoPage({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final fullRoute = detail.waypoints.isNotEmpty
        ? detail.waypoints.map((w) => w.location.cityName).join(' → ')
        : '${detail.departurePoint.cityName} → ${detail.destinationPoint.cityName}';
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: tr('order_detail.sections.route'),
            children: [
              _InfoRow(
                label: tr('order_detail.sections.full_route'),
                value: fullRoute,
              ),
              _InfoRow(
                label: tr('order_detail.sections.loading'),
                value: _locationWithAddress(
                  detail.departurePoint.cityName,
                  detail.departureAddressDetail,
                ),
              ),
              _InfoRow(
                label: tr('order_detail.sections.unloading'),
                value: _locationWithAddress(
                  detail.destinationPoint.cityName,
                  detail.destinationAddressDetail,
                ),
              ),
              _InfoRow(
                label: tr('order_detail.labels.departure_date_title'),
                value: _dateLabel(detail.transportationDate),
              ),
              _InfoRow(
                label: tr('order_detail.labels.delivery_term'),
                value: detail.transportationTermDays != null
                    ? '${detail.transportationTermDays} дн.'
                    : tr('common.not_specified'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _Section(
            title: tr('order_detail.sections.cargo_params'),
            children: [
              _InfoRow(
                label: tr('order_detail.labels.weight'),
                value: '${_formatNumber(detail.weightTons)} т',
              ),
              _InfoRow(
                label: tr('order_detail.labels.volume'),
                value: detail.volumeCubicMeters != null
                    ? '${_formatNumber(detail.volumeCubicMeters!)} м³'
                    : tr('common.not_specified'),
              ),
              _InfoRow(
                label: tr('order_detail.labels.dimensions'),
                value: _dimensionsLabel(
                  detail.lengthMeters,
                  detail.widthMeters,
                  detail.heightMeters,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _Section(
            title: tr('order_detail.sections.cost'),
            children: [
              _InfoRow(
                label: tr('order_detail.labels.budget'),
                value: '${_formatPrice(detail.amount)} ${detail.currency}',
              ),
              _InfoRow(
                label: tr('order_detail.labels.payment_type'),
                value: _paymentLabel(detail),
              ),
              _InfoRow(
                label: tr('order_detail.sections.contacts'),
                value: detail.showPhoneToDrivers
                    ? tr('order_detail.labels.contacts_open')
                    : tr('order_detail.labels.contacts_hidden'),
              ),
            ],
          ),
          if (detail.description != null &&
              detail.description!.trim().isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              tr('order_detail.sections.comment'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              detail.description!.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _BidList extends StatelessWidget {
  const _BidList({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bids = detail.bids;
    if (bids.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('my_cargo.bids.title'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            tr('my_cargo.bids.empty'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${tr('my_cargo.bids.title')} (${bids.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        ...bids.map((bid) => _BidTile(bid: bid)),
      ],
    );
  }
}

class _BidTile extends StatelessWidget {
  const _BidTile({required this.bid});

  final OrderBidInfo bid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.w,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              bid.driverName.isNotEmpty ? bid.driverName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bid.driverName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (bid.amount != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    tr(
                      'my_cargo.bids.offer_amount',
                      args: [bid.amount!.toStringAsFixed(0)],
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                SizedBox(height: 4.h),
                Text(
                  _bidStatusLabel(bid),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bidStatusLabel(OrderBidInfo bid) {
    if (bid.statusLabel.isNotEmpty) return bid.statusLabel;
    final key = 'order_detail.bid_status.${bid.status.toLowerCase()}';
    final translated = tr(key);
    if (translated != key) return translated;
    return tr('order_detail.bid_status.new');
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.steps, required this.currentStatus});

  final List<String> steps;
  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var currentIndex = steps.indexOf(currentStatus);
    if (currentIndex < 0) currentIndex = 0;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            label: _statusLabel(context, steps[i]),
            isActive: i == currentIndex,
            isPassed: i < currentIndex,
            isLast: i == steps.length - 1,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }

  String _statusLabel(BuildContext context, String status) {
    final key = 'order_detail.statuses.${status.toLowerCase()}';
    final translated = tr(key);
    if (translated != key) return translated;
    final fallback = _statusFallbackLabel(context, status.toLowerCase());
    return fallback ?? status;
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.isActive,
    required this.isPassed,
    required this.isLast,
    required this.color,
  });

  final String label;
  final bool isActive;
  final bool isPassed;
  final bool isLast;
  final Color color;

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
                color: isActive
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
                color: isPassed
                    ? color.withValues(alpha: 0.6)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _locationWithAddress(String city, String? address) {
  if (address == null || address.isEmpty) return city;
  return '$city, $address';
}

String _dimensionsLabel(double? l, double? w, double? h) {
  if (l == null && w == null && h == null)
    return tr('dimensions.not_specified');
  final parts = [
    if (l != null) tr('dimensions.length', args: [_formatNumber(l)]),
    if (w != null) tr('dimensions.width', args: [_formatNumber(w)]),
    if (h != null) tr('dimensions.height', args: [_formatNumber(h)]),
  ];
  return parts.join(' · ');
}

String _dateLabel(DateTime? date) {
  if (date == null) return tr('common.date_agreement');
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _paymentLabel(OrderDetail detail) {
  switch (detail.paymentType) {
    case 'CASH':
      return tr('payment_types.cash');
    case 'CASHLESS':
      return tr('payment_types.cashless_no_vat'); // Assuming default cashless
    case 'PREPAYMENT':
      return tr('payment_types.prepayment');
    default:
      return tr('payment_types.agreement');
  }
}

String _vehicleLabel(String value) {
  switch (value) {
    case 'TENT':
      return tr('vehicle_types.tent');
    case 'REF':
      return tr('vehicle_types.ref');
    case 'ISOTHERM':
      return tr('vehicle_types.isotherm');
    case 'ANY':
    default:
      return tr('vehicle_types.any');
  }
}

String _loadingLabel(String value) {
  switch (value) {
    case 'TOP':
      return tr('loading_types.top');
    case 'SIDE':
      return tr('loading_types.side');
    case 'BACK':
      return tr('loading_types.back');
    case 'BACK_SIDE_TOP':
      return tr('loading_types.any_way');
    case 'ANY':
    default:
      return tr('loading_types.any_type');
  }
}

String _formatPrice(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

class _OrderStatusSection extends ConsumerStatefulWidget {
  const _OrderStatusSection({required this.orderId, required this.detail});

  final String orderId;
  final OrderDetail detail;

  @override
  ConsumerState<_OrderStatusSection> createState() =>
      _OrderStatusSectionState();
}

class _OrderStatusSectionState extends ConsumerState<_OrderStatusSection> {
  bool _isProcessing = false;
  static const List<String> _statusFlow = [
    'WAITING_DRIVER_CONFIRMATION',
    'ACCEPTED',
    'READY_FOR_PICKUP',
    'WAITING_PICKUP_CONFIRMATION',
    'IN_PROGRESS',
    'WAITING_DELIVERY_CONFIRMATION',
    'DELIVERED',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = widget.detail.senderId;
    const isSender = true;
    const isAssignedDriver = false;
    const hasOwnBid = false;

    final actions = _buildActions(
      isSender: isSender,
      isAssignedDriver: isAssignedDriver,
      hasOwnBid: hasOwnBid,
      userId: userId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('order_detail.status.title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: Text(
                tr('order_detail.status.current'),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
            Text(
              _statusLabel(context, widget.detail.status),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        if (widget.detail.isFinished &&
            widget.detail.cancellationReason.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              tr(
                'order_detail.status.reason_prefix',
                args: [widget.detail.cancellationReason],
              ),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
        SizedBox(height: 12.h),
        _StatusTimeline(
          steps: _statusFlow,
          currentStatus: widget.detail.status,
        ),
        if (actions.isNotEmpty) ...[
          SizedBox(height: 20.h),
          ...actions.map(
            (config) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _WorkflowButton(config: config, disabled: _isProcessing),
            ),
          ),
        ],
        if (_isProcessing)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  List<_WorkflowButtonConfig> _buildActions({
    required bool isSender,
    required bool isAssignedDriver,
    required bool hasOwnBid,
    String? userId,
  }) {
    final detail = widget.detail;
    final actions = <_WorkflowButtonConfig>[];
    final status = detail.status;
    final cancellableStatuses = {
      'PENDING',
      'WAITING_DRIVER_CONFIRMATION',
      'WAITING_DRIVER_DECISION',
      'ACCEPTED',
      'READY_FOR_PICKUP',
    };
    if (isSender && !detail.isFinished) {
      if (detail.hasAssignedDriver && cancellableStatuses.contains(status)) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.change_driver_title'),
            onPressed: _releaseDriver,
          ),
        );
      }
      if (cancellableStatuses.contains(status)) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.cancel_title'),
            style: _WorkflowActionStyle.danger,
            onPressed: _cancelOrder,
          ),
        );
      }
      final shouldConfirmPickup =
          status == 'WAITING_PICKUP_CONFIRMATION' ||
          (detail.pickupConfirmedByDriver && !detail.pickupConfirmedBySender);
      if (shouldConfirmPickup) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.confirm_pickup'),
            onPressed: _confirmPickup,
          ),
        );
      }
      final shouldConfirmDelivery =
          status == 'WAITING_DELIVERY_CONFIRMATION' ||
          (detail.deliveryConfirmedByDriver &&
              !detail.deliveryConfirmedBySender);
      if (shouldConfirmDelivery) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.confirm_delivery'),
            onPressed: _confirmDelivery,
          ),
        );
      }
    }

    if (hasOwnBid && !detail.isFinished) {
      if (detail.status == 'WAITING_DRIVER_CONFIRMATION' ||
          detail.status == 'WAITING_DRIVER_DECISION') {
        final bid = _pendingBid(userId ?? '');
        if (bid != null) {
          actions.add(
            _WorkflowButtonConfig(
              label: tr('order_detail.actions.confirm_participation'),
              onPressed: () => _driverConfirmBid(bid),
            ),
          );
          actions.add(
            _WorkflowButtonConfig(
              label: tr('order_detail.actions.decline_order'),
              style: _WorkflowActionStyle.secondary,
              onPressed: () => _driverDeclineBid(bid),
            ),
          );
        }
      }
    }

    if (isAssignedDriver && !detail.isFinished) {
      if (!detail.pickupConfirmedByDriver &&
          (detail.status == 'ACCEPTED' ||
              detail.status == 'READY_FOR_PICKUP' ||
              detail.status == 'WAITING_PICKUP_CONFIRMATION')) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.picked_up'),
            onPressed: _markPickedUp,
          ),
        );
      }
      if (!detail.deliveryConfirmedByDriver &&
          (detail.status == 'IN_PROGRESS' ||
              detail.status == 'WAITING_DELIVERY_CONFIRMATION')) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.delivered'),
            onPressed: _markDelivered,
          ),
        );
      }
      if (detail.status == 'ACCEPTED' || detail.status == 'READY_FOR_PICKUP') {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.ready_pickup'),
            onPressed: _markReady,
          ),
        );
      }
      if (detail.pickupConfirmedByDriver) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.send_location'),
            onPressed: _sendLocation,
          ),
        );
      }
      if (!detail.isFinished && detail.hasAssignedDriver) {
        actions.add(
          _WorkflowButtonConfig(
            label: tr('order_detail.actions.release_driver'),
            style: _WorkflowActionStyle.secondary,
            onPressed: _releaseDriver,
          ),
        );
      }
    }

    return actions;
  }

  OrderBidInfo? _pendingBid(String driverId) {
    for (final bid in widget.detail.bids) {
      if (bid.driverId == driverId && bid.status == 'WAITING_DRIVER_DECISION') {
        return bid;
      }
    }
    return null;
  }

  Future<void> _cancelOrder() async {
    final confirmed = await _confirmAction(
      title: tr('order_detail.actions.cancel_title'),
      message: tr('order_detail.actions.cancel_message'),
    );
    if (!confirmed) return;
    await _runOrderAction(
      (repo) => repo.cancelOrder(widget.orderId),
      successMessage: tr('order_detail.actions.cancel_success'),
    );
  }

  Future<void> _releaseDriver() async {
    final confirmed = await _confirmAction(
      title: tr('order_detail.actions.change_driver_title'),
      message: tr('order_detail.actions.change_driver_message'),
    );
    if (!confirmed) return;
    await _runOrderAction(
      (repo) => repo.releaseDriver(widget.orderId),
      successMessage: tr('order_detail.actions.driver_released'),
    );
  }

  Future<void> _confirmPickup() async {
    await _runOrderAction(
      (repo) => repo.confirmPickup(widget.orderId),
      successMessage: 'Передача груза подтверждена',
    );
  }

  Future<void> _confirmDelivery() async {
    await _runOrderAction(
      (repo) => repo.confirmDelivery(widget.orderId),
      successMessage: 'Доставка подтверждена',
    );

    // Show rating sheet if user is sender
    if (mounted) {
      final detail = widget.detail;
      // Check if current user is sender and driver exists
      if (detail.driverName.isNotEmpty) {
        // Small delay to let the success message show
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await showRatingBottomSheet(
            context: context,
            orderId: widget.orderId,
            driverName: detail.driverName,
          );
        }
      }
    }
  }

  Future<void> _markReady() async {
    await _runOrderAction((repo) => repo.markDriverReady(widget.orderId));
  }

  Future<void> _markPickedUp() async {
    await _runOrderAction(
      (repo) => repo.markDriverPickedUp(widget.orderId),
      successMessage: 'Груз отмечен как забранный',
    );
  }

  Future<void> _markDelivered() async {
    await _runOrderAction(
      (repo) => repo.markDriverDelivered(widget.orderId),
      successMessage: 'Доставка отмечена',
    );
  }

  Future<void> _driverConfirmBid(OrderBidInfo bid) async {
    await _runGenericAction(() async {
      final repo = ref.read(orderRepositoryProvider);
      await repo.confirmDriverBid(bid.id);
    }, successMessage: 'Вы подтвердили заказ');
  }

  Future<void> _driverDeclineBid(OrderBidInfo bid) async {
    final confirmed = await _confirmAction(
      title: 'Отказаться от заказа?',
      message: 'Заказ вернётся в общий список.',
    );
    if (!confirmed) return;
    await _runGenericAction(() async {
      final repo = ref.read(orderRepositoryProvider);
      await repo.declineDriverBid(bid.id);
    }, successMessage: 'Вы отказались от заказа');
  }

  Future<void> _sendLocation() async {
    await _runGenericAction(() async {
      final position = await _determinePosition();
      final repo = ref.read(orderRepositoryProvider);
      await repo.submitDriverLocation(
        widget.orderId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }, successMessage: 'Геолокация обновлена');
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
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _runOrderAction(
    Future<OrderDetail> Function(OrderRepository repo) task, {
    String? successMessage,
  }) async {
    await _runGenericAction(
      () async {
        final repo = ref.read(orderRepositoryProvider);
        await task(repo);
      },
      successMessage:
          successMessage ?? tr('order_detail.actions.status_updated'),
    );
  }

  Future<void> _runGenericAction(
    Future<void> Function() task, {
    required String successMessage,
  }) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await task();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось выполнить действие')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _confirmAction({required String title, String? message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: message != null ? Text(message) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _WorkflowButton extends StatelessWidget {
  const _WorkflowButton({required this.config, required this.disabled});

  final _WorkflowButtonConfig config;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPrimary = config.style == _WorkflowActionStyle.primary;
    final isDanger = config.style == _WorkflowActionStyle.danger;
    final backgroundColor = isPrimary
        ? theme.colorScheme.primary
        : isDanger
        ? const Color(0xFFFFEBEE)
        : Colors.white;
    final foregroundColor = isPrimary
        ? Colors.white
        : isDanger
        ? const Color(0xFFE53935)
        : theme.colorScheme.primary;
    final borderColor = isPrimary
        ? Colors.transparent
        : isDanger
        ? const Color(0xFFE53935)
        : theme.colorScheme.primary.withValues(alpha: 0.4);

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        elevation: isPrimary ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: disabled ? null : () => config.onPressed(),
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

class _WorkflowButtonConfig {
  const _WorkflowButtonConfig({
    required this.label,
    required this.onPressed,
    this.style = _WorkflowActionStyle.primary,
  });

  final String label;
  final Future<void> Function() onPressed;
  final _WorkflowActionStyle style;
}

enum _WorkflowActionStyle { primary, secondary, danger }

String _statusLabel(BuildContext context, String status) {
  final key = () {
    switch (status) {
      case 'PENDING':
        return 'order_detail.statuses.waiting_bids';
      case 'WAITING_DRIVER_CONFIRMATION':
        return 'order_detail.statuses.waiting_driver_confirmation';
      case 'ACCEPTED':
        return 'order_detail.statuses.accepted';
      case 'READY_FOR_PICKUP':
        return 'order_detail.statuses.ready_for_pickup';
      case 'WAITING_PICKUP_CONFIRMATION':
        return 'order_detail.statuses.waiting_pickup_confirmation';
      case 'IN_PROGRESS':
        return 'order_detail.statuses.in_progress';
      case 'WAITING_DELIVERY_CONFIRMATION':
        return 'order_detail.statuses.waiting_delivery_confirmation';
      case 'DELIVERED':
        return 'order_detail.statuses.delivered';
      case 'CANCELLED':
        return 'order_detail.statuses.cancelled';
      default:
        return '';
    }
  }();

  if (key.isEmpty) return status;
  final translated = tr(key);
  if (translated != key) return translated;
  final fallback = _statusFallbackLabel(context, key.split('.').last);
  return fallback ?? status;
}

String? _statusFallbackLabel(BuildContext context, String statusKey) {
  final lang = context.locale.languageCode;
  final key = statusKey.toLowerCase();
  String? pick(Map<String, String> map) => map[key];

  const ru = {
    'waiting_bids': 'Ожидает откликов',
    'waiting_driver_confirmation': 'Ждём подтверждения водителя',
    'accepted': 'Водитель назначен',
    'ready_for_pickup': 'Водитель на месте',
    'waiting_pickup_confirmation': 'Ожидает передачи',
    'in_progress': 'В пути',
    'waiting_delivery_confirmation': 'Ожидает подтверждения доставки',
    'delivered': 'Доставлен',
    'cancelled': 'Отменён',
  };
  const en = {
    'waiting_bids': 'Waiting for bids',
    'waiting_driver_confirmation': 'Waiting for driver confirmation',
    'accepted': 'Driver assigned',
    'ready_for_pickup': 'Driver on site',
    'waiting_pickup_confirmation': 'Waiting for pickup handoff',
    'in_progress': 'In transit',
    'waiting_delivery_confirmation': 'Waiting for delivery confirmation',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };
  const kk = {
    'waiting_bids': 'Откликтерді күтуде',
    'waiting_driver_confirmation': 'Жүргізуші растауын күтуде',
    'accepted': 'Жүргізуші тағайындалды',
    'ready_for_pickup': 'Жүргізуші орнында',
    'waiting_pickup_confirmation': 'Тапсыруды күтуде',
    'in_progress': 'Жолда',
    'waiting_delivery_confirmation': 'Жеткізуді растауды күтуде',
    'delivered': 'Жеткізілді',
    'cancelled': 'Бас тартылған',
  };
  const zh = {
    'waiting_bids': '等待响应',
    'waiting_driver_confirmation': '等待司机确认',
    'accepted': '司机已指派',
    'ready_for_pickup': '司机已到场',
    'waiting_pickup_confirmation': '等待交接',
    'in_progress': '运输中',
    'waiting_delivery_confirmation': '等待送达确认',
    'delivered': '已送达',
    'cancelled': '已取消',
  };

  switch (lang) {
    case 'en':
      return pick(en);
    case 'kk':
      return pick(kk);
    case 'zh':
      return pick(zh);
    default:
      return pick(ru);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF00B2FF),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 120.w,
          height: 120.w,
          color: Colors.grey[200],
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            },
            errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }
}
