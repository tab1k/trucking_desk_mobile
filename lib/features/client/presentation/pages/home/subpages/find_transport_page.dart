import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/client/data/repositories/driver_announcement_repository.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement_filters.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/find_transport_filters_page.dart';
import 'package:fura24.kz/features/client/presentation/providers/driver_announcements_provider.dart';
import 'package:fura24.kz/features/client/presentation/widgets/driver_announcement_card.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_announcement_detail_sheet.dart';
import 'package:fura24.kz/features/driver/view/widgets/saved_routes_sheet.dart';
import 'package:fura24.kz/features/driver/domain/models/saved_route.dart';

class FindTransportPage extends ConsumerStatefulWidget {
  const FindTransportPage({super.key});

  @override
  ConsumerState<FindTransportPage> createState() => _FindTransportPageState();
}

class _FindTransportPageState extends ConsumerState<FindTransportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(driverAnnouncementFiltersProvider);
    final hasFilters = filters.toQueryParameters().isNotEmpty;
    final announcementsAsync = ref.watch(driverAnnouncementsProvider);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              tr('find_transport.title'),
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
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            children: [
              _buildSearchRow(hasFilters),
              if (hasFilters) ...[
                SizedBox(height: 10.h),
                _buildFiltersBadge(filters),
              ],
              SizedBox(height: 20.h),
              Text(
                tr('find_transport.available'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              ..._buildAnnouncementWidgets(theme, announcementsAsync),
              SizedBox(height: _bottomSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow(bool hasFilters) {
    final hasQuery = _searchQuery.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr('find_transport.search_hint'),
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
                color: hasFilters ? const Color(0xFF00B2FF) : Colors.grey[200]!,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 28,
                  color: hasFilters
                      ? const Color(0xFF00B2FF)
                      : Color(0xFF00B2FF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersBadge(DriverAnnouncementFilters filters) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: const Color(0xFF00B2FF), size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              tr('find_transport.filters_applied'),
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF1A1D1F)),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(driverAnnouncementFiltersProvider.notifier).reset(),
            child: Text(tr('common.reset')),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnnouncementWidgets(
    ThemeData theme,
    AsyncValue<List<DriverAnnouncement>> async,
  ) {
    return async.when(
      data: (announcements) {
        final filtered = _filterAnnouncements(announcements);
        if (filtered.isEmpty) {
          return [_buildEmptyState(theme)];
        }
        return filtered.map((announcement) {
          final offer = DriverAnnouncementOffer.fromAnnouncement(announcement);
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: GestureDetector(
              onTap: () =>
                  showDriverAnnouncementDetailSheet(context, announcement),
              behavior: HitTestBehavior.opaque,
              child: DriverAnnouncementCard(
                offer: offer,
                onContact: () => showDriverContactSheet(context, offer),
                onFavoriteToggle: () => _toggleFavorite(offer),
              ),
            ),
          );
        }).toList();
      },
      loading: () => [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 50.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (error, _) => [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Text(
              tr('common.error'),
              style: TextStyle(fontSize: 14.sp, color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFilters() async {
    final current = ref.read(driverAnnouncementFiltersProvider);
    final result = await Navigator.of(context).push<DriverAnnouncementFilters>(
      MaterialPageRoute(
        builder: (_) => FindTransportFiltersPage(initialFilters: current),
      ),
    );
    if (result != null) {
      ref
          .read(driverAnnouncementFiltersProvider.notifier)
          .updateFilters(result);
    }
  }

  Future<void> _openSavedRoutes() async {
    final route = await showSavedRoutesSheet(
      context,
      type: SavedRoute.typeTransport,
    );
    if (route != null) {
      if (!mounted) return;
      final current = ref.read(driverAnnouncementFiltersProvider);
      final updated = current.copyWith(
        departureCity: route.departureCityName,
        destinationCity: route.destinationCityName,
      );
      ref
          .read(driverAnnouncementFiltersProvider.notifier)
          .updateFilters(updated);
    }
  }

  List<DriverAnnouncement> _filterAnnouncements(
    List<DriverAnnouncement> items,
  ) {
    final active = _activeAnnouncements(items);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return active;
    return active.where((announcement) {
      final departure = announcement.departurePoint.cityName.toLowerCase();
      final destination = announcement.destinationPoint.cityName.toLowerCase();
      final driver = announcement.driverFullName.toLowerCase();
      final comment = announcement.comment.toLowerCase();
      return departure.contains(query) ||
          destination.contains(query) ||
          driver.contains(query) ||
          comment.contains(query);
    }).toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36.w,
            width: 36.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.info_outline,
              color: theme.colorScheme.primary,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              tr('find_transport.empty'),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: value.isEmpty ? Colors.grey[500] : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  List<DriverAnnouncement> _activeAnnouncements(
    List<DriverAnnouncement> items,
  ) {
    return items.where((announcement) => announcement.isActive).toList();
  }

  double? _parseDouble(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  double _bottomSpacing(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return (bottomInset > 0 ? bottomInset : 0) + 24.h;
  }

  Future<void> _toggleFavorite(DriverAnnouncementOffer offer) async {
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
      _showFavoriteError(error.toString());
    }
  }

  void _showFavoriteError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isNotEmpty ? message : tr('common.error')),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      ),
    );
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }
}
