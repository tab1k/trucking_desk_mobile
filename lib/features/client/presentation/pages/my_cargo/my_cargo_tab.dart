import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/providers/home_tab_provider.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/create_order_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/order_edit_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/order_repeat_page.dart';
import 'package:fura24.kz/features/client/presentation/providers/my_orders_provider.dart';
import 'package:fura24.kz/features/client/presentation/providers/order_detail_provider.dart';
import 'package:fura24.kz/features/client/state/tracked_cargo_notifier.dart';
import 'package:fura24.kz/router/utils/navigation_utils.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/widgets/client_order_detail_sheet.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/widgets/client_bids_page.dart';

class MyCargoTab extends ConsumerStatefulWidget {
  const MyCargoTab({super.key, this.isDriverView = false});

  final bool isDriverView;

  @override
  ConsumerState<MyCargoTab> createState() => _MyCargoTabState();
}

class _MyCargoTabState extends ConsumerState<MyCargoTab> {
  int _currentFilterIndex = 0;
  List<String> get _filters => [
    tr('my_cargo.filters.all'),
    tr('my_cargo.filters.active'),
    tr('my_cargo.filters.completed'),
    tr('my_cargo.filters.cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();
    final backgroundColor =
        widget.isDriverView ? Colors.white : const Color(0xFFF8F9FA);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar:
            widget.isDriverView
                ? _DriverAppBar(canPop: canPop, navigator: navigator)
                : SingleAppbar(title: tr('my_cargo.title')),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фильтры
              _buildFilterChips(),
              SizedBox(height: 16.h),

              // Список грузов
              Expanded(
                child: ordersAsync.when(
                  data: (orders) => _buildCargoList(context, orders),
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _buildErrorState(context, error),
                ),
              ),
            ],
          ),
        ),
        // Кнопка создания нового груза - поднята выше
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 10.h), // Поднимаем над bottom navbar
          child: FloatingActionButton(
            onPressed: () {
              NavigationUtils.navigateWithBottomSheetAnimation(
                context,
                const CreateOrderPage(),
              );
            },
            backgroundColor: Color(0xFF64B5F6), // Новый цвет
            elevation: 4,
            child: Icon(Icons.add, color: Colors.white, size: 24.w),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: CupertinoButton(
              onPressed: () {
                setState(() {
                  _currentFilterIndex = index;
                });
              },
              color:
                  widget.isDriverView
                      ? (_currentFilterIndex == index
                          ? const Color(0xFF2196F3)
                          : CupertinoColors.systemGrey5)
                      : (_currentFilterIndex == index
                          ? const Color(0xFF64B5F6)
                          : CupertinoColors.systemGrey5),
              borderRadius: BorderRadius.circular(20.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color:
                      _currentFilterIndex == index
                          ? Colors.white
                          : CupertinoColors.systemGrey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCargoList(BuildContext context, List<OrderSummary> orders) {
    final cargoItems = orders.map(_cargoItemFromOrder).toList();
    final filteredItems = _filterCargoItems(cargoItems);

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          tr('my_cargo.filters.empty'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final cargo = filteredItems[index];
        return _CargoListItem(cargo: cargo);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final message =
        error is ApiException ? error.message : tr('my_cargo.error.load');
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  List<CargoItem> _filterCargoItems(List<CargoItem> items) {
    if (_currentFilterIndex == 0) return items;

    return items.where((item) {
      switch (_currentFilterIndex) {
        case 1:
          return item.status == CargoStatus.inTransit ||
              item.status == CargoStatus.pending;
        case 2:
          return item.status == CargoStatus.completed;
        case 3:
          return item.status == CargoStatus.cancelled;
        default:
          return true;
      }
    }).toList();
  }

  CargoItem _cargoItemFromOrder(OrderSummary order) {
    return CargoItem(
      id: order.id,
      title: order.cargoName,
      route: order.routeLabel,
      weight: order.weightLabel,
      volume: order.volumeLabel,
      price: order.priceLabel,
      status: order.status,
      rawStatus: order.rawStatus,
      date: order.dateLabel,
      description: order.description,
      bidsCount: order.bidsCount,
      hasNewBids: order.hasNewBids,
      bidDriverPreviewIds: order.bidDriverPreviewIds,
      driverId: order.driverId,
      waypoints: order.waypoints,
    );
  }
}

class _DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DriverAppBar({required this.canPop, required this.navigator});

  final bool canPop;
  final NavigatorState navigator;

  @override
  Size get preferredSize => Size.fromHeight(60.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
            onPressed: () {
              if (canPop) {
                navigator.maybePop();
                return;
              }
              context.go(AppRoutes.driverHome);
            },
          ),
        ),
      ),
      title: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: Text(
          tr('my_cargo.title'),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class CargoItem {
  final String id;
  final String title;
  final String route;
  final String weight;
  final String volume;
  final String price;
  final CargoStatus status;
  final String rawStatus;
  final String date;
  final String description;
  final int bidsCount;
  final bool hasNewBids;
  final List<String> bidDriverPreviewIds;
  final String? driverId;
  final List<OrderWaypointSummary> waypoints;

  CargoItem({
    required this.id,
    required this.title,
    required this.route,
    required this.weight,
    required this.volume,
    required this.price,
    required this.status,
    required this.rawStatus,
    required this.date,
    required this.description,
    required this.bidsCount,
    required this.hasNewBids,
    required this.bidDriverPreviewIds,
    required this.driverId,
    required this.waypoints,
  });
}

class _CargoListItem extends ConsumerStatefulWidget {
  const _CargoListItem({required this.cargo});

  final CargoItem cargo;

  @override
  ConsumerState<_CargoListItem> createState() => _CargoListItemState();
}

class _CargoListItemState extends ConsumerState<_CargoListItem> {
  bool _isDeleting = false;

  bool get _canDelete {
    final status = widget.cargo.status;
    return status == CargoStatus.pending ||
        status == CargoStatus.completed ||
        status == CargoStatus.cancelled;
  }

  void _onDeletePressed(BuildContext context) {
    if (_isDeleting) return;
    if (!_canDelete) {
      _showSnack(
        context,
        'Нельзя удалить заказ, пока он в пути. Завершите или отмените заказ, затем попробуйте снова.',
      );
      return;
    }
    _handleDelete(context);
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await _confirmDeletion(context);
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(orderRepositoryProvider).deleteOrder(widget.cargo.id);
      if (!mounted) return;
      ref.invalidate(myOrdersProvider);
      _showSnack(context, 'Заказ удалён');
    } on ApiException catch (error) {
      _showSnack(context, error.message);
    } catch (_) {
      _showSnack(context, 'Не удалось удалить заказ. Попробуйте позже.');
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool?> _confirmDeletion(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: const Color(0xFFE53935),
                        size: 22.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Удалить объявление?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D1F),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Объявление будет удалено без возможности восстановления.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Отмена'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Удалить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cargo = widget.cargo;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Slidable(
        key: ValueKey('cargo-${cargo.id}'),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            SizedBox(width: 10.w),
            CustomSlidableAction(
              onPressed: (_) => _onDeletePressed(context),
              backgroundColor: _canDelete ? Colors.red : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(16.r),
              padding: EdgeInsets.zero,
              child: Center(
                child:
                    _isDeleting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                        : SvgPicture.asset(
                          'assets/svg/trash.svg',
                          width: 20.w,
                          height: 20.w,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => showClientOrderDetailSheet(context, cargo.id),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'TD-${cargo.id}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          cargo.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                      _statusText(context, cargo.status, rawStatus: cargo.rawStatus),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _statusColor(cargo.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  cargo.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cargo.route,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Builder(
                      builder: (_) {
                        final dateLabel = tr(
                          'order_detail.labels.departure_date',
                          args: [cargo.date],
                        );
                        final display =
                            dateLabel == 'order_detail.labels.departure_date'
                                ? cargo.date
                                : dateLabel;
                        return Text(
                          display,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _CargoSpecItem(
                      iconPath: 'assets/svg/wei.svg',
                      value: cargo.weight,
                    ),
                    SizedBox(width: 16.w),
                    _CargoSpecItem(
                      iconPath: 'assets/svg/ruler.svg',
                      value: cargo.volume,
                    ),
                    const Spacer(),
                    Text(
                      cargo.price,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64B5F6),
                      ),
                    ),
                  ],
                ),
                if (cargo.description.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      cargo.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Text(
                      cargo.date,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const Spacer(),
                    if (cargo.status == CargoStatus.pending ||
                        cargo.status == CargoStatus.inTransit)
                      Row(
                        children: [
                          CupertinoButton(
                            onPressed: () {
                              trackedCargoIdNotifier.value = cargo.id;
                              ref.read(homeTabIndexProvider.notifier).state = 0;
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            padding: EdgeInsets.zero,
                            child: Text(
                              tr('order_detail.actions.track'),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF64B5F6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          CupertinoButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => OrderEditPage(orderId: cargo.id),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            child: Text(
                              tr('order_detail.actions.edit'),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF64B5F6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (cargo.status == CargoStatus.completed)
                      CupertinoButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => OrderRepeatPage(orderId: cargo.id),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        child: Text(
                          tr('order_detail.actions.repeat'),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF64B5F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                if (cargo.driverId == null) ...[
                  _BidResponsesRow(
                    bidsCount: cargo.bidsCount,
                    hasNewBids: cargo.hasNewBids,
                    previewIds: cargo.bidDriverPreviewIds,
                    orderId: cargo.id,
                    orderTitle: cargo.title,
                  ),
                ] else ...[
                  _AssignedStatusDots(rawStatus: cargo.rawStatus),
                ],
              ],
            ),
          ),
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

  String _statusText(
    BuildContext context,
    CargoStatus status, {
    String rawStatus = '',
  }) {
    final rawKey =
        rawStatus.isNotEmpty ? 'order_detail.statuses.${rawStatus.toLowerCase()}' : null;
    if (rawKey != null) {
      final translated = tr(rawKey);
      if (translated != rawKey) return translated;
      final fallback = _statusFallbackLabel(context, rawStatus.toLowerCase());
      if (fallback != null) return fallback;
    }
      final baseKey = () {
        switch (status) {
          case CargoStatus.pending:
            return 'order_detail.statuses.waiting_bids';
          case CargoStatus.inTransit:
            return 'order_detail.statuses.in_progress';
          case CargoStatus.completed:
            return 'order_detail.statuses.delivered';
          case CargoStatus.cancelled:
          return 'order_detail.statuses.cancelled';
        }
      }();
    final baseTranslated = tr(baseKey);
    if (baseTranslated != baseKey) return baseTranslated;
    final fallback = _statusFallbackLabel(context, baseKey.split('.').last);
    if (fallback != null) return fallback;
    return baseKey.split('.').last;
  }
}

class _CargoSpecItem extends StatelessWidget {
  final String iconPath;
  final String value;

  const _CargoSpecItem({required this.iconPath, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 16.w,
          height: 16.w,
          colorFilter: ColorFilter.mode(
            Color(0xFF64B5F6), // Новый цвет
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: CupertinoColors.systemGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BidResponsesRow extends StatelessWidget {
  const _BidResponsesRow({
    required this.bidsCount,
    required this.hasNewBids,
    required this.previewIds,
    required this.orderId,
    required this.orderTitle,
  });

  final int bidsCount;
  final bool hasNewBids;
  final List<String> previewIds;
  final String orderId;
  final String orderTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _pluralize(bidsCount);
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) => ClientBidsPage(orderId: orderId, orderTitle: orderTitle),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            _BidAvatarGroup(driverIds: previewIds),
            SizedBox(width: 10.w),
            Text(
              '$bidsCount',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            Text(
              tr('my_cargo.bids.title'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasNewBids ? const Color(0xFF64B5F6) : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pluralize(int count) {
    final key =
        count == 1
            ? 'order_detail.bid_status.new'
            : 'order_detail.bid_status.new'; // reuse base key, count shown separately
    return tr(key);
  }
}

class _AssignedStatusDots extends StatelessWidget {
  const _AssignedStatusDots({required this.rawStatus});

  final String rawStatus;

  static const _steps = [
    'WAITING_DRIVER_CONFIRMATION',
    'ACCEPTED',
    'READY_FOR_PICKUP',
    'WAITING_PICKUP_CONFIRMATION',
    'IN_PROGRESS',
    'WAITING_DELIVERY_CONFIRMATION',
    'DELIVERED',
  ];

  int _currentIndex() {
    final idx = _steps.indexOf(rawStatus);
    if (idx == -1) return 0;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex();
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: List.generate(_steps.length, (index) {
            final isActive = index <= current;
            final color =
                isActive ? const Color(0xFF64B5F6) : Colors.grey[300]!;
            final label =
                index == 0
                    ? 'A'
                    : index == _steps.length - 1
                    ? 'B'
                    : '';
            final dotSize = label.isNotEmpty ? 14.w : 10.w;
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child:
                        label.isNotEmpty
                            ? Text(
                              label,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color:
                                    isActive ? Colors.white : Colors.grey[600],
                              ),
                            )
                            : null,
                  ),
                  if (index != _steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2.h,
                        color:
                            isActive
                                ? const Color(0xFF64B5F6)
                                : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BidAvatarGroup extends StatelessWidget {
  const _BidAvatarGroup({required this.driverIds});

  final List<String> driverIds;

  @override
  Widget build(BuildContext context) {
    final visible = driverIds.take(5).toList();
    if (visible.isEmpty) {
      return CircleAvatar(
        radius: 16.w,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person_outline, color: Colors.grey[500], size: 18.w),
      );
    }
    final width = 32.w + (visible.length - 1) * 18.w;
    return SizedBox(
      width: width,
      height: 32.w,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(left: i * 18.w, child: _BidAvatar(driverId: visible[i])),
        ],
      ),
    );
  }
}

class _BidAvatar extends StatelessWidget {
  const _BidAvatar({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(driverId);
    final label = _avatarLabel(driverId);
    return CircleAvatar(
      radius: 16.w,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
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
}

class CargoTrackingPage extends ConsumerWidget {
  const CargoTrackingPage({super.key, required this.cargo});

  final CargoItem cargo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeTop = MediaQuery.of(context).padding.top;
    final detailAsync = ref.watch(orderDetailProvider(cargo.id));
    final fallbackStatusColor = _statusColor(cargo.status);
    final fallbackStatusText = _statusText(
      context,
      cargo.status,
      rawStatus: cargo.rawStatus,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: detailAsync.when(
        data: (detail) {
          final tracking = _TrackingData.fromDetail(
            detail,
            fallbackWaypoints: cargo.waypoints,
          );
          final detailStatus = _statusFromRaw(detail.status);
          final statusColor = _statusColor(detailStatus);
          final statusText = _statusText(
            context,
            detailStatus,
            rawStatus: detail.status,
          );

          final markers = <Marker>[
            if (tracking.origin != null)
              Marker(
                point: tracking.origin!,
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const _MapMarker(
                  icon: Icons.flag_circle,
                  color: Color(0xFF00B2FF),
                  label: 'Погрузка',
                ),
              ),
            if (tracking.destination != null)
              Marker(
                point: tracking.destination!,
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const _MapMarker(
                  icon: Icons.check_circle,
                  color: Color(0xFF2EB872),
                  label: 'Доставка',
                ),
              ),
            // Промежуточные точки маршрута
            ...tracking.midpoints.asMap().entries.map(
              (entry) => Marker(
                point: entry.value,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00B2FF),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(0xFF00B2FF),
                    ),
                  ),
                ),
              ),
            ),
            if (tracking.current != null)
              Marker(
                point: tracking.current!,
                width: 54,
                height: 54,
                alignment: Alignment.center,
                child: _MovingTruckMarker(progress: tracking.progress),
              ),
          ];

          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: tracking.mapCenter,
                    initialZoom: tracking.zoom,
                    interactionOptions: const InteractionOptions(
                      flags: ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fura24.kz',
                      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                      tileBuilder: (context, tileWidget, tile) {
                        if (tile.loadError) {
                          return const _OfflineTilePlaceholder();
                        }
                        return tileWidget;
                      },
                    ),
                    if (tracking.polyline.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: tracking.polyline,
                            strokeWidth: 6,
                            color: const Color(0xFF00B2FF),
                          ),
                        ],
                      ),
                    if (markers.isNotEmpty) MarkerLayer(markers: markers),
                  ],
                ),
              ),
              Positioned(
                top: safeTop + 12.h,
                left: 16.w,
                right: 16.w,
                child: _TopOverlay(
                  cargo: cargo,
                  statusColor: statusColor,
                  statusText: statusText,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.32,
                minChildSize: 0.24,
                maxChildSize: 0.65,
                snap: true,
                snapSizes: const [0.32, 0.5],
                builder: (context, controller) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.r),
                        topRight: Radius.circular(24.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.r),
                        topRight: Radius.circular(24.r),
                      ),
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: EdgeInsets.fromLTRB(
                          16.w,
                          20.h,
                          16.w,
                          MediaQuery.of(context).padding.bottom + 24.h,
                        ),
                        child: _TrackingSheetContent(
                          cargo: cargo,
                          detail: detail,
                          tracking: tracking,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
        loading:
            () => Stack(
              children: [
                const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: safeTop + 12.h,
                  left: 16.w,
                  right: 16.w,
                  child: _TopOverlay(
                    cargo: cargo,
                    statusColor: fallbackStatusColor,
                    statusText: fallbackStatusText,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
        error:
            (error, _) => Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      'Не удалось загрузить маршрут заказа',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: safeTop + 12.h,
                  left: 16.w,
                  right: 16.w,
                  child: _TopOverlay(
                    cargo: cargo,
                    statusColor: fallbackStatusColor,
                    statusText: fallbackStatusText,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  CargoStatus _statusFromRaw(String raw) {
    switch (raw) {
      case 'IN_PROGRESS':
      case 'ACCEPTED':
      case 'READY_FOR_PICKUP':
      case 'WAITING_DRIVER_CONFIRMATION':
      case 'WAITING_PICKUP_CONFIRMATION':
      case 'WAITING_DELIVERY_CONFIRMATION':
        return CargoStatus.inTransit;
      case 'DELIVERED':
        return CargoStatus.completed;
      case 'CANCELLED':
        return CargoStatus.cancelled;
      default:
        return CargoStatus.pending;
    }
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

  String _statusText(
    BuildContext context,
    CargoStatus status, {
    String rawStatus = '',
  }) {
    final rawKey =
        rawStatus.isNotEmpty ? 'order_detail.statuses.${rawStatus.toLowerCase()}' : null;
    if (rawKey != null) {
      final translated = tr(rawKey);
      if (translated != rawKey) return translated;
      final fallback = _statusFallbackLabel(context, rawStatus.toLowerCase());
      if (fallback != null) return fallback;
    }
    final baseKey = () {
      switch (status) {
        case CargoStatus.pending:
          return 'order_detail.statuses.waiting_bids';
        case CargoStatus.inTransit:
          return 'order_detail.statuses.in_progress';
        case CargoStatus.completed:
          return 'order_detail.statuses.delivered';
        case CargoStatus.cancelled:
          return 'order_detail.statuses.cancelled';
      }
    }();
    final baseTranslated = tr(baseKey);
    if (baseTranslated != baseKey) return baseTranslated;
    final fallback = _statusFallbackLabel(context, baseKey.split('.').last);
    if (fallback != null) return fallback;
    return baseKey.split('.').last;
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.onBack,
    required this.cargo,
    required this.statusColor,
    required this.statusText,
  });

  final VoidCallback onBack;
  final CargoItem cargo;
  final Color statusColor;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Material(
            color: Colors.grey[200],
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cargo.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  cargo.route,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingSheetContent extends StatelessWidget {
  const _TrackingSheetContent({
    required this.cargo,
    required this.detail,
    required this.tracking,
  });

  final CargoItem cargo;
  final OrderDetail detail;
  final _TrackingData tracking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastUpdate = tracking.lastUpdate;
    final departureTime =
        detail.readyAt ?? detail.acceptedAt ?? detail.createdAt;
    final plannedArrival =
        detail.deliveredAt ??
        detail.deliveryConfirmedAt ??
        detail.transportationDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Осталось в пути',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.social_distance,
                label: 'Осталось',
                value: _formatDistance(tracking.remainingDistanceKm),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _InfoChip(
                icon: Icons.access_time,
                label: 'Обновлено',
                value: _formatDateTime(lastUpdate),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          'Прогресс доставки',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: tracking.progress,
            minHeight: 6.h,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00B2FF)),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Отправлено: ${_formatDateTime(departureTime)}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            Text(
              'Планово: ${_formatDateTime(plannedArrival)}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          'Данные груза',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.inventory_2,
                label: 'Вес',
                value: cargo.weight,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _InfoChip(
                icon: Icons.aspect_ratio,
                label: 'Объем',
                value: cargo.volume,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _InfoChip(
                icon: Icons.payments,
                label: 'Ставка',
                value: cargo.price,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          'Маршрут',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        _RouteTimeline(detail: detail, tracking: tracking),
      ],
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({required this.detail, required this.tracking});

  final OrderDetail detail;
  final _TrackingData tracking;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(detail);
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 16.h),
            child: _TimelineStep(data: steps[i], isLast: i == steps.length - 1),
          ),
      ],
    );
  }

  List<_TimelineStepData> _buildSteps(OrderDetail detail) {
    final steps = <_TimelineStepData>[
      _TimelineStepData(
        title:
            detail.departurePoint.cityName.isEmpty
                ? 'Точка отправления'
                : detail.departurePoint.cityName,
        subtitle:
            detail.departureAddressDetail?.trim().isNotEmpty == true
                ? detail.departureAddressDetail!.trim()
                : 'Адрес не указан',
        timestamp: tracking.startedAt,
        state: _originState(detail),
      ),
      if (detail.lastLocation != null)
        _TimelineStepData(
          title: 'Текущее местоположение',
          subtitle:
              detail.lastLocation!.note.isNotEmpty
                  ? detail.lastLocation!.note
                  : '${detail.lastLocation!.latitude.toStringAsFixed(3)}, '
                      '${detail.lastLocation!.longitude.toStringAsFixed(3)}',
          timestamp: detail.lastLocation!.reportedAt,
          state: _TimelineState.current,
        ),
      _TimelineStepData(
        title:
            detail.destinationPoint.cityName.isEmpty
                ? 'Точка доставки'
                : detail.destinationPoint.cityName,
        subtitle:
            detail.destinationAddressDetail?.trim().isNotEmpty == true
                ? detail.destinationAddressDetail!.trim()
                : 'Адрес не указан',
        timestamp:
            detail.deliveredAt ??
            detail.deliveryConfirmedAt ??
            detail.transportationDate,
        state: _destinationState(detail),
      ),
    ];

    return steps;
  }

  _TimelineState _originState(OrderDetail detail) {
    if (detail.pickupConfirmedAt != null ||
        detail.status == 'WAITING_DELIVERY_CONFIRMATION' ||
        detail.status == 'DELIVERED') {
      return _TimelineState.completed;
    }
    if (detail.status == 'ACCEPTED' ||
        detail.status == 'READY_FOR_PICKUP' ||
        detail.status == 'WAITING_PICKUP_CONFIRMATION') {
      return _TimelineState.current;
    }
    return _TimelineState.pending;
  }

  _TimelineState _destinationState(OrderDetail detail) {
    if (detail.deliveryConfirmedAt != null || detail.status == 'DELIVERED') {
      return _TimelineState.completed;
    }
    if (detail.status == 'WAITING_DELIVERY_CONFIRMATION') {
      return _TimelineState.current;
    }
    return _TimelineState.pending;
  }
}

class _TimelineStepData {
  const _TimelineStepData({
    required this.title,
    required this.subtitle,
    required this.state,
    this.timestamp,
  });

  final String title;
  final String subtitle;
  final _TimelineState state;
  final DateTime? timestamp;
}

enum _TimelineState { pending, current, completed }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.data, required this.isLast});

  final _TimelineStepData data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineIndicator(state: data.state, isLast: isLast),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                data.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              if (data.timestamp != null) ...[
                SizedBox(height: 4.h),
                Text(
                  _formatDateTime(data.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineIndicator extends StatelessWidget {
  const _TimelineIndicator({required this.state, required this.isLast});

  final _TimelineState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _indicatorColor(state);
    return Column(
      children: [
        Container(
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                state == _TimelineState.pending
                    ? Colors.white
                    : color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 40.h,
            margin: EdgeInsets.symmetric(vertical: 4.h),
            color: color.withValues(
              alpha: state == _TimelineState.pending ? 0.2 : 0.5,
            ),
          ),
      ],
    );
  }

  Color _indicatorColor(_TimelineState state) {
    switch (state) {
      case _TimelineState.completed:
        return const Color(0xFF2EB872);
      case _TimelineState.current:
        return const Color(0xFF00B2FF);
      case _TimelineState.pending:
        return const Color(0xFFB0BEC5);
    }
  }
}

String _formatDistance(double? value) {
  if (value == null) return '—';
  final normalized = value < 0 ? 0 : value;
  if (normalized >= 100) return '${normalized.toStringAsFixed(0)} км';
  if (normalized >= 10) return '${normalized.toStringAsFixed(1)} км';
  return '${normalized.toStringAsFixed(2)} км';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final formatter = DateFormat('dd MMM, HH:mm');
  return formatter.format(value);
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: const Color(0xFF00B2FF)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineTilePlaceholder extends StatelessWidget {
  const _OfflineTilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.grey[500], size: 24.w),
          SizedBox(height: 6.h),
          Text(
            'Нет связи с картой',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.w,
      height: 40.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(4.w),
            child: Icon(icon, size: 18.w, color: color),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovingTruckMarker extends StatelessWidget {
  const _MovingTruckMarker({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(8.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 38.w,
            height: 38.w,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00B2FF)),
            ),
          ),
          const Icon(Icons.local_shipping, color: Color(0xFF00B2FF), size: 20),
        ],
      ),
    );
  }
}

class _TrackingData {
  const _TrackingData({
    required this.origin,
    required this.destination,
    required this.current,
    required this.midpoints,
    required this.polyline,
    required this.totalDistanceKm,
    required this.coveredDistanceKm,
    required this.startedAt,
    required this.lastUpdate,
    required this.isDelivered,
  });

  final LatLng? origin;
  final LatLng? destination;
  final LatLng? current;
  final List<LatLng> midpoints;
  final List<LatLng> polyline;
  final double? totalDistanceKm;
  final double? coveredDistanceKm;
  final DateTime? startedAt;
  final DateTime? lastUpdate;
  final bool isDelivered;

  double get progress {
    if (totalDistanceKm == null || totalDistanceKm == 0) {
      if (isDelivered) return 1;
      if (current != null) return 0.5;
      return 0;
    }
    final fallback = isDelivered ? totalDistanceKm : 0.0;
    final covered = coveredDistanceKm ?? fallback ?? 0.0;
    return (covered / totalDistanceKm!).clamp(0.0, 1.0);
  }

  double? get remainingDistanceKm {
    if (totalDistanceKm == null) return null;
    final covered = coveredDistanceKm ?? (isDelivered ? totalDistanceKm : 0.0);
    if (covered == null) return totalDistanceKm;
    final remaining = totalDistanceKm! - covered;
    return remaining <= 0 ? 0.0 : remaining;
  }

  LatLng get mapCenter {
    final points = <LatLng>[
      ...polyline,
      if (current != null) current!,
    ];
    if (points.isEmpty) {
      return const LatLng(48.0196, 66.9237);
    }
    final lat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    return LatLng(lat, lng);
  }

  double get zoom {
    final points = <LatLng>[
      ...polyline,
      if (current != null) current!,
    ];
    if (points.length < 2) {
      return current != null ? 11 : 5.5;
    }
    final maxDistance = _maxDistance(points);
    if (maxDistance > 1500) return 4.0;
    if (maxDistance > 800) return 4.8;
    if (maxDistance > 400) return 5.4;
    if (maxDistance > 200) return 6.2;
    if (maxDistance > 80) return 7.4;
    return 9.2;
  }

  static _TrackingData fromDetail(
    OrderDetail detail, {
    List<OrderWaypointSummary> fallbackWaypoints = const [],
  }) {
    final origin = _latLngFromCoords(
      detail.departurePoint.latitude,
      detail.departurePoint.longitude,
    );
    final destination = _latLngFromCoords(
      detail.destinationPoint.latitude,
      detail.destinationPoint.longitude,
    );
    final canShowDriver = _canShowDriverPosition(
      detail.status,
      detail.isDriverSharingLocation,
    );
    final lastLocation =
        canShowDriver
            ? detail.lastLocation ?? detail.currentDriverLocation
            : null;
    final current =
        lastLocation != null
            ? _latLngFromCoords(lastLocation.latitude, lastLocation.longitude)
            : null;
    final totalDistanceKm = _distanceInKm(origin, destination);
    final isDelivered = detail.status == 'DELIVERED';
    double? coveredDistanceKm;
    if (origin != null && current != null) {
      coveredDistanceKm = _distanceInKm(origin, current);
    } else if (isDelivered) {
      coveredDistanceKm = totalDistanceKm;
    }
    final startedAt = detail.readyAt ?? detail.acceptedAt ?? detail.createdAt;
    final lastUpdate =
        canShowDriver
            ? lastLocation?.reportedAt ??
                detail.deliveryConfirmedAt ??
                detail.pickupConfirmedAt ??
                startedAt
            : startedAt;
    final waypointModels =
        detail.waypoints.toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
    var waypointCoords =
        waypointModels
            .map(
              (w) =>
                  _latLngFromCoords(w.location.latitude, w.location.longitude),
            )
            .whereType<LatLng>()
            .toList();
    final fallbackSorted = fallbackWaypoints.toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final fallbackCoords =
        fallbackSorted
            .map(
              (w) =>
                  _latLngFromCoords(
                    _parseNum(w.location['latitude']),
                    _parseNum(w.location['longitude']),
                  ),
            )
            .whereType<LatLng>()
            .toList();
    if (fallbackCoords.isNotEmpty) {
      final uniqueFallback = _uniquePoints(fallbackCoords);
      final uniqueWaypoints = _uniquePoints(waypointCoords);
      final shouldUseFallback =
          uniqueWaypoints.length < 2 ||
          uniqueFallback.length > uniqueWaypoints.length;
      if (shouldUseFallback && uniqueFallback.length >= 2) {
        waypointCoords = uniqueFallback;
      }
    }

    final routePath = <LatLng>[];
    if (waypointCoords.length >= 2) {
      if (origin != null && !_samePoint(origin, waypointCoords.first)) {
        routePath.add(origin);
      }
      routePath.addAll(waypointCoords);
      if (destination != null &&
          !_samePoint(routePath.last, destination)) {
        routePath.add(destination);
      }
    } else {
      if (origin != null) routePath.add(origin);
      if (waypointCoords.length == 1) {
        final lone = waypointCoords.first;
        if (routePath.isEmpty || !_samePoint(routePath.last, lone)) {
          routePath.add(lone);
        }
      }
      if (destination != null &&
          (routePath.isEmpty || !_samePoint(routePath.last, destination))) {
        routePath.add(destination);
      }
    }

    if (routePath.length < 2 &&
        origin != null &&
        destination != null &&
        !_samePoint(origin, destination)) {
      routePath
        ..clear()
        ..addAll([origin, destination]);
    }

    final cleanedRoute = <LatLng>[];
    for (final point in routePath) {
      if (cleanedRoute.isEmpty || !_samePoint(cleanedRoute.last, point)) {
        cleanedRoute.add(point);
      }
    }

    final midLatLng = <LatLng>[];
    if (cleanedRoute.length > 2) {
      for (var i = 1; i < cleanedRoute.length - 1; i++) {
        final point = cleanedRoute[i];
        if (midLatLng.isEmpty || !_samePoint(midLatLng.last, point)) {
          midLatLng.add(point);
        }
      }
    }

    return _TrackingData(
      origin: origin,
      destination: destination,
      current: current,
      midpoints: List.unmodifiable(midLatLng),
      polyline: List.unmodifiable(cleanedRoute),
      totalDistanceKm: totalDistanceKm,
      coveredDistanceKm: coveredDistanceKm,
      startedAt: startedAt,
      lastUpdate: lastUpdate,
      isDelivered: isDelivered,
    );
  }

  static bool _canShowDriverPosition(String status, bool isSharingLocation) {
    if (!isSharingLocation) return false;
    switch (status) {
      case 'IN_PROGRESS':
      case 'WAITING_PICKUP_CONFIRMATION':
      case 'WAITING_DELIVERY_CONFIRMATION':
      case 'READY_FOR_PICKUP':
        return true;
      default:
        return false;
    }
  }

  static LatLng? _latLngFromCoords(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  static double? _distanceInKm(LatLng? a, LatLng? b) {
    if (a == null || b == null) return null;
    return _distance.distance(a, b) / 1000;
  }

  static double _maxDistance(List<LatLng> points) {
    var maxValue = 0.0;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final value = _distance.distance(points[i], points[j]) / 1000;
        if (value > maxValue) {
          maxValue = value;
        }
      }
    }
    return maxValue;
  }

  static bool _samePoint(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.0001 &&
        (a.longitude - b.longitude).abs() < 0.0001;
  }

  static List<LatLng> _uniquePoints(List<LatLng> points) {
    final result = <LatLng>[];
    for (final point in points) {
      final exists = result.any((p) => _samePoint(p, point));
      if (!exists) {
        result.add(point);
      }
    }
    return result;
  }

  static double? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  static const Distance _distance = Distance();
}

String? _statusFallbackLabel(BuildContext context, String statusKey) {
  final lang = context.locale.languageCode;
  final key = statusKey.toLowerCase();
  String? pick(Map<String, String> map) => map[key];

  const ru = {
    'waiting_bids': 'Ожидает откликов',
    'waiting_driver_confirmation': 'Ожидает подтверждения водителя',
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
