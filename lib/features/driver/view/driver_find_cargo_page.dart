import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/domain/models/driver_cargo_filters.dart';
import 'package:fura24.kz/features/driver/domain/models/saved_route.dart';
import 'package:fura24.kz/features/driver/providers/available_orders_provider.dart';
import 'package:fura24.kz/features/driver/providers/responded_orders_provider.dart';
import 'package:fura24.kz/features/driver/utils/driver_order_actions.dart';
import 'package:fura24.kz/features/driver/utils/driver_verification_guard.dart';
import 'package:fura24.kz/features/driver/view/driver_cargo_filters_page.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_order_card.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_order_detail_sheet.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_respond_sheet.dart';
import 'package:fura24.kz/features/driver/view/widgets/saved_routes_sheet.dart';

class DriverFindCargoPage extends ConsumerStatefulWidget {
  const DriverFindCargoPage({super.key});

  @override
  ConsumerState<DriverFindCargoPage> createState() =>
      _DriverFindCargoPageState();
}

class _DriverFindCargoPageState extends ConsumerState<DriverFindCargoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DriverCargoFilters _filters = const DriverCargoFilters();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(driverAvailableOrdersProvider(_filters));

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
              tr('driver_find.title'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_outline, color: Colors.black87),
              onPressed: _openSavedRoutes,
            ),
          ],
        ),

        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: ordersAsync.when(
              data: (orders) {
                final filtered = _filterOrders(orders);
                return _DriverCargoList(
                  header: _buildHeader(),
                  orders: filtered,
                  filters: _filters,
                  isFiltered: _searchQuery.isNotEmpty || !_filters.isEmpty,
                  onRefresh: () async {
                    await ref.refresh(
                      driverAvailableOrdersProvider(_filters).future,
                    );
                  },
                  onFavoriteToggle: (order) =>
                      toggleDriverOrderFavorite(context, ref, order),
                );
              },
              loading: () => _ScrollableShell(
                header: _buildHeader(),
                child: const _DriverCargoLoading(),
              ),
              error: (error, _) {
                final message = error is ApiException
                    ? error.message
                    : tr('driver_find.error');
                return _ScrollableShell(
                  header: _buildHeader(),
                  child: _DriverCargoError(
                    message: message,
                    onRetry: () =>
                        ref.invalidate(driverAvailableOrdersProvider(_filters)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr('driver_find.search_hint'),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(color: Color(0xFF00B2FF)),
              ),
            ),
            style: TextStyle(fontSize: 15.sp),
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          height: 52.h,
          child: OutlinedButton(
            onPressed: _openFilters,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              side: BorderSide(
                color: Colors.grey.shade200, // Светло-серый цвет границы
                width: 1.0, // Толщина границы
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [Icon(Icons.tune, size: 30)],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<DriverCargoFilters>(
      MaterialPageRoute(
        builder: (_) => DriverCargoFiltersPage(initialFilters: _filters),
      ),
    );
    if (result != null) {
      setState(() {
        _filters = result;
      });
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchRow(context),
        SizedBox(height: 5.h),
      ],
    );
  }

  List<OrderSummary> _filterOrders(List<OrderSummary> orders) {
    final query = _searchQuery.toLowerCase();
    final filterDate = _filters.transportationDate;
    return orders.where((order) {
      if (_filters.onlyWithCall && !order.canDriverCall) {
        return false;
      }
      if (filterDate != null) {
        final orderDate = order.transportationDate ?? order.createdAt;
        if (orderDate == null || !DateUtils.isSameDay(orderDate, filterDate)) {
          return false;
        }
      }
      if (query.isEmpty) return true;
      final values = [
        order.routeLabel,
        order.cargoName,
        order.description,
        order.vehicleTypeLabel,
        order.departureCity,
        order.destinationCity,
        order.senderName,
      ];
      return values.any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _openSavedRoutes() async {
    final route = await showSavedRoutesSheet(context);
    if (route != null) {
      if (!mounted) return;
      setState(() {
        _filters = _filters.copyWith(
          departureCity: route.departureCityName,
          destinationCity: route.destinationCityName,
          departurePointId: route.departureCity,
          destinationPointId: route.destinationCity,
        );
      });
    }
  }
}

class _ScrollableShell extends StatelessWidget {
  const _ScrollableShell({required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      children: [
        header,
        SizedBox(height: 8.h),
        child,
      ],
    );
  }
}

class _DriverCargoLoading extends StatelessWidget {
  const _DriverCargoLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _DriverCargoError extends StatelessWidget {
  const _DriverCargoError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black.withOpacity(0.75),
              ),
            ),
            SizedBox(height: 12.h),
            FilledButton(
              onPressed: onRetry,
              child: Text(tr('driver_find.retry_filters')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCargoList extends ConsumerWidget {
  const _DriverCargoList({
    required this.orders,
    required this.onRefresh,
    required this.onFavoriteToggle,
    required this.header,
    required this.filters,
    this.isFiltered = false,
  });

  final List<OrderSummary> orders;
  final Future<void> Function() onRefresh;
  final Future<void> Function(OrderSummary) onFavoriteToggle;
  final Widget header;
  final DriverCargoFilters filters;
  final bool isFiltered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final respondedOrders = ref.watch(respondedOrdersProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final itemCount = orders.isEmpty ? 2 : orders.length + 1;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + bottomInset),
        itemBuilder: (context, index) {
          if (index == 0) {
            return header;
          }
          if (orders.isEmpty) {
            return _DriverEmptyState(isFiltered: isFiltered);
          }
          final order = orders[index - 1];
          return DriverOrderCard(
            order: order,
            isResponded:
                order.hasResponded || respondedOrders.contains(order.id),
            onRespond: () => _respondToOrder(context, ref, order),
            onTap: () => _openOrderDetail(context, order),
            onCall: order.canDriverCall
                ? () => callOrderSender(context, order)
                : null,
            onWhatsApp: order.canDriverCall
                ? () => openOrderWhatsApp(context, order)
                : null,
            onToggleFavorite: () async {
              await onFavoriteToggle(order);
              ref.invalidate(driverAvailableOrdersProvider(filters));
            },
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemCount: itemCount,
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
        const SnackBar(content: Text('Отклик отправлен отправителю')),
      );
    }
  }

  Future<void> _openOrderDetail(BuildContext context, OrderSummary order) {
    return showDriverOrderDetailSheet(context, order);
  }
}

class _DriverEmptyState extends StatelessWidget {
  const _DriverEmptyState({required this.isFiltered});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: Center(
        child: Text(
          isFiltered
              ? 'Объявления не найдены. Измените поиск или фильтры.'
              : 'Подходящих грузов пока нет. Попробуйте позже.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
