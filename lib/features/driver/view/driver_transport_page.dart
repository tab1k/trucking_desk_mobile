import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/client/presentation/widgets/driver_announcement_card.dart';
import 'package:fura24.kz/features/client/data/repositories/driver_announcement_repository.dart';
import 'package:fura24.kz/features/driver/view/driver_create_announcement_page.dart';
import 'package:fura24.kz/features/driver/providers/driver_announcements_provider.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_announcement_detail_sheet.dart';
import 'package:fura24.kz/features/driver/utils/driver_verification_guard.dart';
import 'package:fura24.kz/features/notifications/providers/notifications_provider.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class DriverTransportPage extends ConsumerStatefulWidget {
  const DriverTransportPage({super.key});

  @override
  ConsumerState<DriverTransportPage> createState() => _DriverTransportPageState();
}

class _DriverTransportPageState extends ConsumerState<DriverTransportPage> {
  @override
  void initState() {
    super.initState();
    // Всегда подгружаем свежие объявления при открытии страницы.
    Future.microtask(() => ref.refresh(driverMyAnnouncementsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(driverMyAnnouncementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: SingleAppbar(title: tr('driver_transport.title')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: announcementsAsync.when(
            data: (announcements) => _DriverAnnouncementList(
              announcements: announcements,
              onRefresh: () async {
                await ref.refresh(driverMyAnnouncementsProvider.future);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              final message =
                  error is ApiException
                      ? error.message
                      : tr('driver_transport.error_load');
              return _DriverAnnouncementError(
                message: message,
                onRetry: () => ref.invalidate(driverMyAnnouncementsProvider),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: FloatingActionButton(
          onPressed: () async {
            final allowed = await ensureDriverVerified(context, ref);
            if (!allowed) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DriverCreateAnnouncementPage(),
              ),
            );
          },
          backgroundColor: const Color(0xFF64B5F6),
          elevation: 4,
          child: Icon(Icons.add, color: Colors.white, size: 24.w),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _DriverAnnouncementList extends StatelessWidget {
  const _DriverAnnouncementList({
    required this.announcements,
    required this.onRefresh,
  });

  final List<DriverAnnouncement> announcements;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child:
          announcements.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 80.h),
                children: const [
                  _DriverAnnouncementEmptyState(),
                ],
              )
              : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 4.h,
                  bottom: bottomInset + 72.h,
                ),
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  return _DriverAnnouncementListItem(
                    announcement: announcement,
                  );
                },
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemCount: announcements.length,
              ),
    );
  }
}

class _DriverAnnouncementListItem extends ConsumerStatefulWidget {
  const _DriverAnnouncementListItem({required this.announcement});

  final DriverAnnouncement announcement;

  @override
  ConsumerState<_DriverAnnouncementListItem> createState() =>
      _DriverAnnouncementListItemState();
}

class _DriverAnnouncementListItemState
    extends ConsumerState<_DriverAnnouncementListItem> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final offer = DriverAnnouncementOffer.fromAnnouncement(widget.announcement);
    final notifications = ref.read(notificationsControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Slidable(
        key: ValueKey('driver-ann-${widget.announcement.id}'),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.26,
          children: [
            SizedBox(width: 10.w),
            CustomSlidableAction(
              onPressed: (_) => _onDeletePressed(context),
              backgroundColor: Colors.red,
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
          onTap: () => showDriverAnnouncementDetailSheet(
            context,
            widget.announcement,
          ),
          behavior: HitTestBehavior.opaque,
          child: DriverAnnouncementCard(
            offer: offer,
            onContact: () => showDriverContactSheet(context, offer),
            onFavoriteToggle: null,
            showFavoriteButton: false,
            routeTrailing: _DriverAnnouncementStatusChip(
              isActive: widget.announcement.isActive,
            ),
            bottomTrailing: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DriverCreateAnnouncementPage(
                          initialAnnouncement: widget.announcement,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(tr('driver_transport.edit')),
                ),
                Text(
                  'Создано ${_formatDate(context, widget.announcement.createdAt)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    if (_isDeleting) return;
    final confirmed = await _confirmDelete(context);
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    final repo = ref.read(driverAnnouncementRepositoryProvider);
    final notifications = ref.read(notificationsControllerProvider.notifier);
    try {
      await repo.deleteAnnouncement(widget.announcement.id);
      if (!mounted) return;
      ref.invalidate(driverMyAnnouncementsProvider);
      await notifications.removeByEntity(widget.announcement.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('driver_transport.deleted'))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      ref.invalidate(driverMyAnnouncementsProvider);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
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
                        tr('driver_transport.delete_title'),
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
                  tr('driver_transport.delete_message'),
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
                        child: Text(tr('driver_transport.cancel')),
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
                        child: Text(tr('driver_transport.delete')),
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
}

class _DriverAnnouncementStatusChip extends StatelessWidget {
  const _DriverAnnouncementStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? tr('driver_transport.status_active') : tr('driver_transport.status_hidden'),
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DriverAnnouncementEmptyState extends StatelessWidget {
  const _DriverAnnouncementEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          tr('driver_transport.empty'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _DriverAnnouncementError extends StatelessWidget {
  const _DriverAnnouncementError({
    required this.message,
    required this.onRetry,
  });

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
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black.withOpacity(0.75),
              ),
            ),
            SizedBox(height: 12.h),
            FilledButton(
              onPressed: onRetry,
              child: Text(tr('driver_transport.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime date) {
  final locale = context.locale.toLanguageTag();
  return DateFormat('dd MMM yyyy', locale).format(date);
}
