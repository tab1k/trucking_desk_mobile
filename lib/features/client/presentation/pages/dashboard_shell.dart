import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import 'package:fura24.kz/features/client/presentation/pages/home/home_tab.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/my_cargo_tab.dart';
import 'package:fura24.kz/features/client/presentation/pages/profile/profile_tab.dart';
import 'package:fura24.kz/features/client/presentation/pages/rides/rides_tab.dart';
import 'package:fura24.kz/features/client/presentation/providers/home_tab_provider.dart';

class MyHomePageView extends ConsumerWidget {
  const MyHomePageView({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(homeTabIndexProvider);

    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        appBar: null,
        backgroundColor: const Color(0xFFF8F9FA),
        extendBody: false,
        body: IndexedStack(
          index: tabIndex,
          children: const [
            HomeTab(),
            RidesTab(),
            MyCargoTab(),
            ProfileTab(),
          ],
        ),
        bottomNavigationBar: _CustomBottomNavBar(
          currentIndex: tabIndex,
          onTap: (i) => ref.read(homeTabIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

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
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 70.h,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                children: [
                  _NavBarItem(
                    icon: 'assets/svg/truck-check.svg',
                    activeIcon: 'assets/svg/truck-check-filled.svg',
                    label: 'Заказ',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavBarItem(
                    icon: 'assets/svg/heart.svg',
                    activeIcon: 'assets/svg/heart-filled.svg',
                    label: 'Избранное',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavBarItem(
                    icon: 'assets/svg/dolly-flatbed.svg',
                    activeIcon: 'assets/svg/dolly-flatbed-filled.svg',
                    label: 'Мои грузы',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _NavBarItem(
                    icon: 'assets/svg/circle-user.svg',
                    activeIcon: 'assets/svg/circle-user-filled.svg',
                    label: 'Профиль',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
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
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                isActive ? activeIcon : icon,
                width: 24.r,
                height: 24.r,
                colorFilter: ColorFilter.mode(
                  isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
