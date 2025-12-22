import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/client/data/repositories/driver_announcement_repository.dart';
import 'package:fura24.kz/features/client/presentation/providers/driver_announcements_provider.dart';
import 'package:fura24.kz/features/client/presentation/widgets/driver_announcement_card.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteDriverAnnouncementsProvider);
    Future<void> refreshFavorites() async {
      ref.invalidate(driverAnnouncementsProvider);
      await ref.refresh(favoriteDriverAnnouncementsProvider.future);
    }

    return Scaffold(
      appBar: SingleAppbar(title: tr('favorites.title')),
      body: RefreshIndicator(
        onRefresh: refreshFavorites,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: favoritesAsync.when(
            data: (announcements) {
              if (announcements.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: 120.h),
                    Center(
                      child: Text(
                        tr('favorites.empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16.h,
                ),
                itemCount: announcements.length,
                separatorBuilder: (_, __) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  final offer = DriverAnnouncementOffer.fromAnnouncement(
                    announcements[index],
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showTransportDetail(context, offer),
                    child: DriverAnnouncementCard(
                      offer: offer,
                      onContact: () => showDriverContactSheet(context, offer),
                      onFavoriteToggle: () => _toggleFavorite(context, ref, offer),
                    ),
                  );
                },
              );
            },
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 180.h),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (error, _) {
              final message = error.toString();
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 120.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: Colors.redAccent),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    DriverAnnouncementOffer offer,
  ) async {
    final repository = ref.read(driverAnnouncementRepositoryProvider);
    try {
      if (offer.isFavorite) {
        await repository.removeFavorite(offer.id);
      } else {
        await repository.addFavorite(offer.id);
      }
      ref.refresh(driverAnnouncementsProvider);
      ref.refresh(favoriteDriverAnnouncementsProvider);
    } catch (error) {
      _showFavoriteError(context, error.toString());
    }
  }

  void _showFavoriteError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      ),
    );
  }

  Future<void> _showTransportDetail(
    BuildContext context,
    DriverAnnouncementOffer offer,
  ) async {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            child: Material(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  12.h,
                  16.w,
                  bottomInset + 16.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${offer.origin} → ${offer.destination}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1D1F),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      offer.company,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _detailRow(
                      icon: Icons.local_shipping_outlined,
                      label: tr('find_transport.detail.vehicle'),
                      value: offer.vehicle,
                    ),
                    SizedBox(height: 10.h),
                    _detailRow(
                      icon: Icons.inventory_2_outlined,
                      label: tr('find_transport.detail.loading'),
                      value: offer.loadType,
                    ),
                    SizedBox(height: 10.h),
                    _detailRow(
                      icon: Icons.fitness_center_outlined,
                      label: tr('find_transport.detail.capacity'),
                      value:
                          '${offer.capacity} ${tr('find_transport.card.capacity_unit')}',
                    ),
                    SizedBox(height: 10.h),
                    _detailRow(
                      icon: Icons.width_normal_rounded,
                      label: tr('find_transport.detail.volume'),
                      value:
                          offer.volume > 0
                              ? '${offer.volume} ${tr('find_transport.card.volume_unit')}'
                              : '—',
                    ),
                    if (offer.tags.isNotEmpty) ...[
                      SizedBox(height: 14.h),
                      Text(
                        tr('find_transport.detail.comment'),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          offer.tags.join('\n'),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 18.w, color: Colors.grey[700]),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D1F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
