import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/pages/my_cargo/widgets/client_order_detail_sheet.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_order_detail_sheet.dart';
import 'package:fura24.kz/features/notifications/domain/app_notification.dart';
import 'package:fura24.kz/features/notifications/providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _markedOnOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationsControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsControllerProvider);

    ref.listen<AsyncValue<List<AppNotification>>>(
      notificationsControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (items) {
            if (!_markedOnOpen && items.isNotEmpty) {
              _markedOnOpen = true;
              ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllAsRead();
            }
          },
        );
      },
    );

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
              tr('notifications_page.title'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsControllerProvider.notifier).refresh(),
            child: notificationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 140),
                      _NotificationsEmpty(),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 24.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(notificationsControllerProvider.notifier)
                            .deleteNotification(item.id);
                      },
                      child: _NotificationCard(
                        item: item,
                        onTap: () => _handleNotificationTap(item),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 160.h),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 160.h),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        tr('notifications_page.load_error'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 13.5.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(AppNotification item) async {
    debugPrint(
      '[Notifications] Tapped item: id=${item.id}, entityId=${item.entityId}, type=${item.type}, role=${item.role}',
    );
    final entityId = item.entityId;
    if (entityId == null || entityId.isEmpty) {
      debugPrint('[Notifications] Entity ID is empty, ignoring.');
      return;
    }

    if (item.type == 'order_status_update' || item.type == 'order_bid') {
      // Check role to decide destination
      final isDriver = item.role == 'driver';

      if (isDriver) {
        try {
          // Show transparent loader or just wait? Better to show loader.
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final repo = ref.read(orderRepositoryProvider);
          final detail = await repo.fetchOrderDetail(entityId);
          if (!mounted) return;
          Navigator.of(context).pop(); // Dismiss loader

          // Convert to summary and show sheet
          final summary = OrderSummary.fromDetail(detail);
          showDriverOrderDetailSheet(context, summary);
        } catch (e) {
          if (!mounted) return;
          Navigator.of(context).pop(); // Dismiss loader if error
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('notifications_page.order_load_error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Client - ID is enough
        showClientOrderDetailSheet(context, entityId);
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(item.type);
    final isUnread = !item.isRead;
    final localizedTitle = _localizedTitle(context, item);
    final localizedBody = _localizedBody(context, item);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isUnread ? accent.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isUnread ? accent.withOpacity(0.2) : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Color(0xFF2196F3).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/notifications.svg',
                  width: 20.w,
                  height: 20.h,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizedTitle,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        _formatTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    localizedBody,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.black.withOpacity(0.7),
                      height: 1.35,
                    ),
                  ),
                  if (isUnread) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          tr('notifications_page.unread'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/notifications.svg',
              width: 64.w,
              height: 64.h,
              colorFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.7),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              tr('notifications_page.empty_title'),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              tr('notifications_page.empty_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black.withOpacity(0.65),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _accentColor(String? type) {
  switch (type) {
    case 'driver_announcement_created':
      return const Color(0xFF0E4ECF);
    case 'order_status_update':
      return const Color(0xFF00B8A9);
    case 'order_bid':
      return const Color(0xFFFFA000);
    default:
      return const Color(0xFF0E4ECF);
  }
}

String _localizedTitle(BuildContext context, AppNotification item) {
  final type = item.type ?? '';
  final code = _extractOrderCode(item.body) ??
      _extractOrderCode(item.title) ??
      item.entityId;
  final key = 'notifications_page.types.$type.title';
  final translated = tr(key, args: [code ?? '']).replaceAll('{0}', code ?? '');
  if (translated != key) return translated;
  if (item.title.isNotEmpty) {
    return item.title.replaceAll('{0}', code ?? '');
  }
  return tr('notifications_page.default_title');
}

String _localizedBody(BuildContext context, AppNotification item) {
  final type = item.type ?? '';
  final code = _extractOrderCode(item.body) ??
      _extractOrderCode(item.title) ??
      item.entityId;
  final key = 'notifications_page.types.$type.body';
  final translated = tr(key, args: [code ?? '']).replaceAll('{0}', code ?? '');
  if (translated != key) return translated;
  if (item.body.isNotEmpty) {
    return item.body.replaceAll('{0}', code ?? '');
  }
  return tr('notifications_page.default_body');
}

String? _extractOrderCode(String text) {
  final match = RegExp(r'(TD-[0-9]+)').firstMatch(text);
  if (match != null) return match.group(1);
  return null;
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);
  if (difference.inDays == 0) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
  if (difference.inDays == 1) return tr('notifications_page.yesterday');
  final day = time.day.toString().padLeft(2, '0');
  final month = time.month.toString().padLeft(2, '0');
  return '$day.$month';
}
