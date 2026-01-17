import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BusinessServicesPage extends ConsumerStatefulWidget {
  const BusinessServicesPage({super.key});

  @override
  ConsumerState<BusinessServicesPage> createState() =>
      _BusinessServicesPageState();
}

class _BusinessServicesPageState extends ConsumerState<BusinessServicesPage> {
  LocationModel? _selectedCity;

  @override
  Widget build(BuildContext context) {
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
              tr('driver_profile.balance.business'),
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
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            children: [
              Text(
                tr('driver_profile.business_page.header_subtitle'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64B5F6),
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                tr('driver_profile.business_page.title'),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                tr('driver_profile.business_page.subtitle'),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              _buildCitySelector(),
              SizedBox(height: 24.h),
              _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return InkWell(
      onTap: () async {
        final selection = await showModalBottomSheet<LocationPickerSelection>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.9,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Material(
                color: Colors.white,
                child: LocationPickerSheet(
                  title: tr('driver_profile.business_page.city_label'),
                ),
              ),
            ),
          ),
        );

        if (selection != null) {
          setState(() {
            _selectedCity = selection.location;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCity?.cityName ??
                    tr('driver_profile.business_page.city_label'),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: _selectedCity != null
                      ? Colors.black
                      : Colors.grey[600],
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F9),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              tr('driver_profile.business_page.empty_title'),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              tr('driver_profile.business_page.empty_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
