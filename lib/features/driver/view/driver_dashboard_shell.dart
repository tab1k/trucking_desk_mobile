import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/driver/providers/driver_assigned_orders_provider.dart';
import 'package:fura24.kz/features/driver/providers/driver_dashboard_tab_provider.dart';
import 'package:fura24.kz/features/driver/providers/driver_location_sharing_provider.dart';
import 'package:fura24.kz/features/driver/view/tabs/driver_home_tab.dart';
import 'package:fura24.kz/features/driver/view/driver_profile_page.dart';
import 'package:fura24.kz/features/driver/view/driver_favorites_page.dart';
import 'package:fura24.kz/features/driver/view/driver_transport_page.dart';

class DriverDashboardShellPage extends ConsumerStatefulWidget {
  const DriverDashboardShellPage({super.key});

  @override
  ConsumerState<DriverDashboardShellPage> createState() =>
      _DriverDashboardShellPageState();
}

class _DriverDashboardShellPageState
    extends ConsumerState<DriverDashboardShellPage> {
  ProviderSubscription<AsyncValue<List<OrderSummary>>>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _ordersSubscription = ref.listenManual(
      driverAssignedOrdersProvider,
      (previous, next) {
        next.whenData(
          (orders) =>
              ref.read(driverLocationSharingProvider).updateOrders(orders),
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _ordersSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(driverDashboardTabIndexProvider);
    final localeKey = context.locale.languageCode;
    final tabs = [
      _DriverTabItem(
        label: tr('driver_tabs.home'),
        iconAsset: 'assets/svg/house-blank.svg',
        activeIconAsset: 'assets/svg/house-blank-filled.svg',
        builder: DriverHomeTab(key: ValueKey('driver-home-$localeKey')),
      ),
      _DriverTabItem(
        label: tr('driver_tabs.favorites'),
        iconAsset: 'assets/svg/heart.svg',
        activeIconAsset: 'assets/svg/heart-filled.svg',
        builder: DriverFavoritesPage(key: ValueKey('driver-fav-$localeKey')),
      ),
      _DriverTabItem(
        label: tr('driver_tabs.transport'),
        iconAsset: 'assets/svg/cars.svg',
        activeIconAsset: 'assets/svg/cars.svg',
        builder:
            DriverTransportPage(key: ValueKey('driver-transport-$localeKey')),
      ),
      _DriverTabItem(
        label: tr('driver_tabs.profile'),
        iconAsset: 'assets/svg/circle-user.svg',
        activeIconAsset: 'assets/svg/circle-user-filled.svg',
        builder:
            DriverProfilePage(key: ValueKey('driver-profile-$localeKey')),
      ),
    ];

    final overlayStyle =
        Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
            : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        extendBody: false,
        body: IndexedStack(
          index: tabIndex,
          children: tabs.map((tab) => tab.builder).toList(),
        ),
        bottomNavigationBar: _DriverBottomNavigationBar(
          currentIndex: tabIndex,
          onTap:
              (index) =>
                  ref.read(driverDashboardTabIndexProvider.notifier).state =
                      index,
          items: tabs,
        ),
      ),
    );
  }
}

class _DriverTabItem {
  const _DriverTabItem({
    required this.label,
    required this.iconAsset,
    required this.activeIconAsset,
    required this.builder,
  });

  final String label;
  final String iconAsset;
  final String activeIconAsset;
  final Widget builder;
}

class _DriverBottomNavigationBar extends StatelessWidget {
  const _DriverBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_DriverTabItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 72.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _DriverNavItem(
                      item: items[i],
                      isActive: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 2.h,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}

class _DriverNavItem extends StatelessWidget {
  const _DriverNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _DriverTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                isActive ? item.activeIconAsset : item.iconAsset,
                width: 22.r,
                height: 22.r,
                colorFilter: ColorFilter.mode(
                  isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
