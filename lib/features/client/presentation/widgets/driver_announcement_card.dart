import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';

class DriverAnnouncementOffer {
  const DriverAnnouncementOffer({
    required this.id,
    required this.origin,
    required this.destination,
    required this.routeLabel,
    required this.date,
    required this.vehicle,
    required this.loadType,
    required this.capacity,
    required this.volume,
    required this.price,
    required this.company,
    required this.rating,
    required this.driverPhoneNumber,
    this.driverPhoto,
    required this.whatsappUrl,
    required this.isFavorite,
    this.tags = const [],
  });

  final String id;
  final String origin;
  final String destination;
  final String routeLabel;
  final DateTime date;
  final String vehicle;
  final String loadType;
  final double capacity;
  final double volume;
  final String price;
  final String company;
  final double rating;
  final String driverPhoneNumber;
  final String? driverPhoto;
  final String whatsappUrl;
  final bool isFavorite;
  final List<String> tags;

  factory DriverAnnouncementOffer.fromAnnouncement(
    DriverAnnouncement announcement,
  ) {
    final comment = announcement.comment.trim();
    final phone = announcement.driverPhoneNumber;
    return DriverAnnouncementOffer(
      id: announcement.id,
      origin: announcement.departurePoint.cityName,
      destination: announcement.destinationPoint.cityName,
      routeLabel: announcement.routeLabel(),
      date: announcement.createdAt,
      vehicle: announcement.vehicleTypeDisplay,
      loadType: announcement.loadingTypeDisplay,
      capacity: announcement.weight,
      volume: announcement.volume ?? 0,
      price: tr('find_transport.card.price_on_request'),
      company: announcement.driverFullName.isNotEmpty
          ? announcement.driverFullName
          : tr('find_transport.card.driver_placeholder'),
      rating: announcement.driverRating,
      driverPhoneNumber: phone,
      driverPhoto: announcement.driverPhoto,
      whatsappUrl: _buildWhatsAppUrl(phone),
      tags: comment.isNotEmpty ? [comment] : const [],
      isFavorite: announcement.isFavorite,
    );
  }
}

String _buildWhatsAppUrl(String phoneNumber) {
  final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return '';
  }
  return 'https://wa.me/$digits';
}

Future<void> showDriverContactSheet(
  BuildContext parentContext,
  DriverAnnouncementOffer offer,
) {
  return showModalBottomSheet<void>(
    context: parentContext,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, bottomInset + 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(height: 16.h),
            Text(
              tr('driver_contact.title'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              offer.company,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 10.h),
            if (offer.driverPhoneNumber.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 20.w,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: SvgPicture.asset(
                    'assets/svg/phone.svg',
                    width: 20.w,
                    height: 20.h,
                    colorFilter: const ColorFilter.mode(
                      Colors.green,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(tr('driver_contact.call')),
                subtitle: Text(offer.driverPhoneNumber),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _launchUri(
                    parentContext,
                    Uri(scheme: 'tel', path: offer.driverPhoneNumber),
                    tr('driver_contact.call_error'),
                  );
                },
              ),
            if (offer.whatsappUrl.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 20.w,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: SvgPicture.asset(
                    'assets/svg/whatsapp.svg',
                    width: 20.w,
                    height: 20.h,
                    colorFilter: const ColorFilter.mode(
                      Colors.green,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(tr('driver_contact.whatsapp')),
                subtitle: Text(offer.driverPhoneNumber),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _launchUri(
                    parentContext,
                    Uri.parse(offer.whatsappUrl),
                    tr('driver_contact.whatsapp_error'),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _launchUri(
  BuildContext context,
  Uri uri,
  String errorMessage,
) async {
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
  } catch (_) {
    // ignored
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
    ),
  );
}

class DriverAnnouncementCard extends StatelessWidget {
  const DriverAnnouncementCard({
    required this.offer,
    required this.onContact,
    this.onFavoriteToggle,
    this.showFavoriteButton = true,
    this.routeTrailing,
    this.bottomTrailing,
  });

  final DriverAnnouncementOffer offer;
  final VoidCallback onContact;
  final VoidCallback? onFavoriteToggle;
  final bool showFavoriteButton;
  final Widget? routeTrailing;
  final Widget? bottomTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratingText = offer.rating.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'TD-${offer.id}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.star, color: Colors.amber, size: 16.w),
              SizedBox(width: 4.w),
              Text(
                ratingText,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 12.w),
              if (showFavoriteButton)
                _FavoriteButton(
                  isFavorite: offer.isFavorite,
                  onPressed: onFavoriteToggle,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      offer.routeLabel.isNotEmpty
                          ? offer.routeLabel
                          : '${offer.origin} → ${offer.destination}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (routeTrailing != null) ...[
                    SizedBox(width: 8.w),
                    routeTrailing!,
                  ],
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                tr(
                  'find_transport.card.created_at',
                  args: [_formatDate(offer.date)],
                ),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.vehicle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${offer.loadType} · '
                      '${offer.capacity.toStringAsFixed(1)} '
                      '${tr('find_transport.card.capacity_unit')} · '
                      '${offer.volume.toStringAsFixed(1)} '
                      '${tr('find_transport.card.volume_unit')}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    offer.price,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tr('find_transport.card.per_trip'),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              CircleAvatar(
                radius: 18.w,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                backgroundImage:
                    offer.driverPhoto != null && offer.driverPhoto!.isNotEmpty
                    ? NetworkImage(offer.driverPhoto!)
                    : null,
                child:
                    offer.driverPhoto != null && offer.driverPhoto!.isNotEmpty
                    ? null
                    : Text(
                        offer.company.isNotEmpty
                            ? offer.company.characters.first
                            : '',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  offer.company,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: onContact,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: Text(tr('find_transport.card.contact')),
              ),
            ],
          ),
          if (offer.tags.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: offer.tags.map((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                );
              }).toList(),
            ),
          ],
          if (bottomTrailing != null) ...[
            SizedBox(height: 8.h),
            Align(alignment: Alignment.centerRight, child: bottomTrailing!),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      tr('common.months_short.jan'),
      tr('common.months_short.feb'),
      tr('common.months_short.mar'),
      tr('common.months_short.apr'),
      tr('common.months_short.may'),
      tr('common.months_short.jun'),
      tr('common.months_short.jul'),
      tr('common.months_short.aug'),
      tr('common.months_short.sep'),
      tr('common.months_short.oct'),
      tr('common.months_short.nov'),
      tr('common.months_short.dec'),
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, this.onPressed});

  final bool isFavorite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final defaultColor = Colors.grey[500];
    final iconColor = onPressed == null
        ? defaultColor?.withOpacity(0.3)
        : isFavorite
        ? const Color(0xFFE53935)
        : defaultColor;

    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: IconButton(
        onPressed: onPressed,
        constraints: BoxConstraints.tightFor(width: 32.w, height: 32.w),
        splashRadius: 20.w,
        padding: EdgeInsets.zero,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: iconColor,
          size: 22.w,
        ),
      ),
    );
  }
}
