import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';

Future<void> showDriverAnnouncementDetailSheet(
  BuildContext context,
  DriverAnnouncement announcement,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _DriverAnnouncementDetail(announcement: announcement),
  );
}

class _DriverAnnouncementDetail extends StatelessWidget {
  const _DriverAnnouncementDetail({required this.announcement});

  final DriverAnnouncement announcement;

  String _formatLocation(LocationModel loc) {
    // If cityName starts with a digit (likely coordinates), preferably show Country
    if (RegExp(r'^\d').hasMatch(loc.cityName.trim())) {
      return loc.country.isNotEmpty ? loc.country : loc.cityName;
    }
    // Otherwise show "City, Country" if country is available
    if (loc.country.isNotEmpty) {
      return '${loc.cityName}, ${loc.country}';
    }
    return loc.cityName;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final stops =
        announcement.waypoints.isNotEmpty
            ? announcement.waypoints
                .map((w) => _formatLocation(w.location))
                .toList()
            : <String>[
                _formatLocation(announcement.departurePoint),
                _formatLocation(announcement.destinationPoint),
              ];
    final fullRoute = stops.join(' → ');

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottomInset + safeBottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              fullRoute,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              tr(
                'find_transport.detail.created_at',
                args: [_formatDate(announcement.createdAt)],
              ),
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 14.h),
            _RouteStops(stops: stops),
            SizedBox(height: 16.h),
            _InfoBlock(
              title: tr('find_transport.detail.transport_title'),
              rows: [
                _InfoRow(
                  label: tr('find_transport.detail.vehicle'),
                  value: announcement.vehicleTypeDisplay,
                ),
                _InfoRow(
                  label: tr('find_transport.detail.loading'),
                  value: announcement.loadingTypeDisplay,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _InfoBlock(
              title: tr('find_transport.detail.cargo_title'),
              rows: [
                _InfoRow(
                  label: tr('find_transport.detail.capacity'),
                  value:
                      '${announcement.weight.toStringAsFixed(1)} ${tr('find_transport.card.capacity_unit')}',
                ),
                _InfoRow(
                  label: tr('find_transport.detail.volume'),
                  value: announcement.volume != null
                      ? '${announcement.volume!.toStringAsFixed(1)} ${tr('find_transport.card.volume_unit')}'
                      : '—',
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _InfoBlock(
              title: tr('find_transport.detail.status_title'),
              rows: [
                _InfoRow(
                  label: tr('find_transport.detail.show_listing'),
                  value: announcement.isActive
                      ? tr('find_transport.detail.yes')
                      : tr('find_transport.detail.no'),
                ),
              ],
            ),
            if (announcement.comment.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              _InfoBlock(
                title: tr('find_transport.detail.comment'),
                rows: [
                  _InfoRow(label: '', value: announcement.comment.trim()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          ...rows.map((row) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: row,
              )),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel)
          SizedBox(
            width: 140.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
            ),
          ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteStops extends StatelessWidget {
  const _RouteStops({required this.stops});

  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('find_transport.detail.route_title'),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10.h),
          ...stops.asMap().entries.map((entry) {
            final isLast = entry.key == stops.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00B2FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2.w,
                          height: 16.h,
                          color: Colors.grey[300],
                        ),
                    ],
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
