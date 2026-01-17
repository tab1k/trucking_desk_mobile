import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fura24.kz/features/client/data/repositories/banner_repository.dart';
import 'package:fura24.kz/features/client/domain/models/banner_model.dart';
import 'package:fura24.kz/core/config/app_config.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/models/home_quick_action.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/cost_estimate_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/action_card.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/calculate_card.dart';
import 'package:fura24.kz/features/client/presentation/providers/my_orders_provider.dart';
import 'package:fura24.kz/features/notifications/providers/notifications_provider.dart';
import 'package:fura24.kz/features/notifications/view/notifications_page.dart';
import 'package:fura24.kz/router/utils/navigation_utils.dart';

class HomeBottomSheet extends ConsumerWidget {
  const HomeBottomSheet({
    super.key,
    required this.scrollController,
    required this.onQuickActionSelected,
  });

  final ScrollController scrollController;
  final ValueChanged<HomeQuickAction> onQuickActionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsControllerProvider);
    final myOrdersAsync = ref.watch(myOrdersProvider);
    final unreadCount = notificationsAsync.maybeWhen(
      data: (items) => items.where((n) => !n.isRead).length,
      orElse: () => 0,
    );
    final newBidsCount = myOrdersAsync.maybeWhen(
      data: (orders) => orders.where((o) => o.hasNewBids).length,
      orElse: () => 0,
    );
    final totalBadgeCount = unreadCount + newBidsCount;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: Stack(
          children: [
            _HomeSheetContent(
              scrollController: scrollController,
              onQuickActionSelected: onQuickActionSelected,
              unreadCount: totalBadgeCount,
            ),
            Positioned(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSheetContent extends StatelessWidget {
  const _HomeSheetContent({
    required this.scrollController,
    required this.onQuickActionSelected,
    required this.unreadCount,
  });

  final ScrollController scrollController;
  final ValueChanged<HomeQuickAction> onQuickActionSelected;
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
                    tr('home.actions.title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    tr('home.actions.subtitle'),
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
                          width: 22.w,
                          height: 22.h,
                          color: Colors.black,
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
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/plus.svg',
                    title: tr('home.actions.create_order_title'),
                    onTap: () =>
                        onQuickActionSelected(HomeQuickAction.createOrder),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/search.svg',
                    title: tr('home.actions.find_transport_title'),
                    onTap: () =>
                        onQuickActionSelected(HomeQuickAction.findRide),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/box.svg',
                    title: tr('home.actions.my_cargo_title'),
                    onTap: () => onQuickActionSelected(HomeQuickAction.myCargo),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: HomeActionCard(
                    iconAsset: 'assets/svg/history.svg',
                    title: tr('home.actions.history_title'),
                    onTap: () => onQuickActionSelected(HomeQuickAction.history),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 18.h),
        const BannerStoriesStrip(),
        SizedBox(height: 12.h),
        HomeCalculateCard(
          onTap: () => NavigationUtils.navigateWithBottomSheetAnimation(
            context,
            const CostEstimatePage(),
          ),
        ),
      ],
    );
  }
}

class BannerStoriesStrip extends ConsumerWidget {
  const BannerStoriesStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(activeBannersProvider);
    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 130.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: banners.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) =>
                _BannerStoryCard(banner: banners[index]),
          ),
        );
      },
      loading: () => SizedBox(
        height: 130.h,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
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

class _BannerStoryCard extends StatelessWidget {
  const _BannerStoryCard({required this.banner});

  final BannerModel banner;

  ImageProvider _imageProvider() {
    final url = banner.imageUrl;
    if (url == null) {
      return const AssetImage('assets/img/truck.jpg');
    }
    if (url.startsWith('asset:')) {
      final assetPath = url.replaceFirst('asset:', '');
      return AssetImage(assetPath);
    }
    if (url.contains('via.placeholder.com')) {
      return const AssetImage('assets/img/truck.jpg');
    }
    return NetworkImage(_resolveImageUrl(url));
  }

  void _openStory(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image(
                    image: _imageProvider(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey.shade900),
                  ),
                ),
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color.fromARGB(200, 0, 0, 0),
                          Color.fromARGB(80, 0, 0, 0),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      banner.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _openStory(context),
      child: SizedBox(
        width: 95.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  width: 1.4,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: SizedBox(
                  height: 92.h,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image(
                          image: _imageProvider(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade600,
                              size: 28.w,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (banner.link != null && banner.link!.isNotEmpty)
                        Positioned(
                          top: 10.h,
                          left: 10.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'PRO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 8.w,
                        right: 12.w,
                        bottom: 12.h,
                        child: Text(
                          banner.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              banner.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                fontSize: 12.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveImageUrl(String raw) {
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return raw;
  }
  final uri = Uri.parse(AppConfig.apiBaseUrl);
  final base =
      '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  final normalized = raw.startsWith('/') ? raw : '/$raw';
  return '$base$normalized';
}
