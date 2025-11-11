import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fura24.kz/features/driver/providers/driver_dashboard_tab_provider.dart';
import 'package:fura24.kz/features/driver/view/tabs/driver_home_tab.dart';
import 'package:fura24.kz/features/driver/view/tabs/driver_finances_tab.dart';
import 'package:fura24.kz/features/driver/view/tabs/driver_trips_tab.dart';
import 'package:fura24.kz/features/driver/view/driver_profile_page.dart';

class DriverDashboardShellPage extends ConsumerWidget {
  const DriverDashboardShellPage({super.key});

  static final List<_DriverTabItem> _tabs = [
    _DriverTabItem(
      label: 'Главная',
      iconAsset: 'assets/svg/house-blank.svg',
      activeIconAsset: 'assets/svg/house-blank-filled.svg',
      builder: const DriverHomeTab(),
    ),
    _DriverTabItem(
      label: 'Рейсы',
      iconAsset: 'assets/svg/truck-check.svg',
      activeIconAsset: 'assets/svg/truck-check-filled.svg',
      builder: const DriverTripsTab(),
    ),
    _DriverTabItem(
      label: 'Кошелек',
      iconAsset: 'assets/svg/wallet.svg',
      activeIconAsset: 'assets/svg/wallet.svg',
      builder: const DriverFinancesTab(),
    ),
    _DriverTabItem(
      label: 'Профиль',
      iconAsset: 'assets/svg/circle-user.svg',
      activeIconAsset: 'assets/svg/circle-user-filled.svg',
      builder: const DriverProfilePage(),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(driverDashboardTabIndexProvider);

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
          children: _tabs.map((tab) => tab.builder).toList(),
        ),
        bottomNavigationBar: _DriverBottomNavigationBar(
          currentIndex: tabIndex,
          onTap:
              (index) =>
                  ref.read(driverDashboardTabIndexProvider.notifier).state =
                      index,
          items: _tabs,
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
              top: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
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
          child: Container(height: 2.h, color: Colors.black.withOpacity(0.05)),
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
                width: 24.r,
                height: 24.r,
                colorFilter: ColorFilter.mode(
                  isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
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
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
