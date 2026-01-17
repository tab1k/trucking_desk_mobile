import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/create_order_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/find_transport_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/home_bottom_sheet.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/my_cargo_tab.dart';
import 'package:fura24.kz/features/driver/view/driver_expenses_page.dart';
import 'package:fura24.kz/features/driver/view/driver_find_cargo_page.dart';
import 'package:fura24.kz/features/driver/view/driver_loading_status_page.dart';
import 'package:fura24.kz/features/driver/view/driver_history_page.dart';
import 'package:fura24.kz/features/notifications/providers/notifications_provider.dart';
import 'package:fura24.kz/features/notifications/view/notifications_page.dart';
import 'package:fura24.kz/router/utils/navigation_utils.dart';

enum DriverQuickAction {
  startTrip,
  confirmLoading,
  addExpense,
  contactDispatcher,
}

const _driverActionColor = Color(0xFF00B2FF);

class DriverHomeBottomSheet extends ConsumerWidget {
  const DriverHomeBottomSheet({
    super.key,
    required this.scrollController,
    this.onQuickActionSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<DriverQuickAction>? onQuickActionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsControllerProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (items) => items.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
        ),
        child: Stack(
          children: [
            _DriverSheetContent(
              scrollController: scrollController,
              onQuickActionSelected: onQuickActionSelected,
              unreadCount: unreadCount,
            ),
            const _SheetHandle(),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 64,
          height: 20,
          alignment: Alignment.topCenter,
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverSheetContent extends StatelessWidget {
  const _DriverSheetContent({
    required this.scrollController,
    required this.onQuickActionSelected,
    required this.unreadCount,
  });

  final ScrollController scrollController;
  final ValueChanged<DriverQuickAction>? onQuickActionSelected;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('driver_home.actions.title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    tr('driver_home.actions.subtitle'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () =>
                        NavigationUtils.navigateWithBottomSheetAnimation(
                          context,
                          const NotificationsPage(),
                        ),
                    child: SizedBox(
                      width: 48.w,
                      height: 48.w,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/svg/notifications.svg',
                          width: 24.w,
                          height: 24.h,
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -4.h,
                    right: -4.w,
                    child: _NotificationBadge(count: unreadCount),
                  ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/truck-moving.svg',
                    title: tr('driver_home.actions.find_cargo'),
                    color: _driverActionColor,
                    onTap: () {
                      NavigationUtils.navigateWithBottomSheetAnimation(
                        context,
                        const DriverFindCargoPage(),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/plus.svg',
                    title: tr('driver_home.actions.create_ad'),
                    color: _driverActionColor,
                    onTap: () {
                      NavigationUtils.navigateWithBottomSheetAnimation(
                        context,
                        const CreateOrderPage(),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/calculator.svg',
                    title: tr('driver_home.actions.expenses'),
                    color: _driverActionColor,
                    onTap: () {
                      NavigationUtils.navigateWithBottomSheetAnimation(
                        context,
                        const DriverExpensesPage(),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _DriverActionCard(
                    iconAsset: 'assets/svg/history.svg',
                    title: tr('driver_home.actions.history'),
                    color: _driverActionColor,
                    onTap: () {
                      NavigationUtils.navigateWithBottomSheetAnimation(
                        context,
                        const DriverHistoryPage(),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _DriverActionListTile(
              iconAsset: 'assets/svg/truck-loading.svg',
              title: tr('driver_home.actions.loading_status'),
              subtitle: tr('driver_home.actions.current_orders'),
              onTap: () {
                NavigationUtils.navigateWithBottomSheetAnimation(
                  context,
                  const DriverLoadingStatusPage(),
                );
              },
            ),

            SizedBox(height: 8.h),
            _DriverActionListTile(
              iconAsset: 'assets/svg/search.svg',
              title: tr('driver_home.actions.find_transport'),
              subtitle: tr('driver_home.actions.companion'),
              onTap: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                }
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => const FindTransportPage()),
                );
              },
            ),

            SizedBox(height: 8.h),
            _DriverActionListTile(
              iconAsset: 'assets/svg/box.svg',
              title: tr('driver_home.actions.my_ads'),
              subtitle: tr('driver_home.actions.ads_subtitle'),
              onTap: () {
                NavigationUtils.navigateWithBottomSheetAnimation(
                  context,
                  const MyCargoTab(isDriverView: true),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 18.h),
        const BannerStoriesStrip(),
        SizedBox(height: 12.h),
      ],
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : '$count';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DriverActionCard extends StatelessWidget {
  const _DriverActionCard({
    required this.iconAsset,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          height: 100.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withOpacity(0.20), width: 0.6),
          ),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 20.r,
                      height: 20.r,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverActionListTile extends StatelessWidget {
  const _DriverActionListTile({
    required this.iconAsset,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _driverActionColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _driverActionColor.withOpacity(0.20),
              width: 0.6,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.all(6.r),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: _driverActionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 18.w,
                      height: 18.h,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
