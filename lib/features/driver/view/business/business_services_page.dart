import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/business/data/models/partner_model.dart';
import 'package:fura24.kz/features/business/data/repositories/partner_repository.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';

class BusinessServicesPage extends ConsumerStatefulWidget {
  const BusinessServicesPage({super.key});

  @override
  ConsumerState<BusinessServicesPage> createState() =>
      _BusinessServicesPageState();
}

class _BusinessServicesPageState extends ConsumerState<BusinessServicesPage> {
  LocationModel? _selectedCity;
  late Future<List<PartnerModel>> _partnersFuture;

  @override
  void initState() {
    super.initState();
    _partnersFuture = _loadPartners();
  }

  Future<List<PartnerModel>> _loadPartners() {
    final repo = ref.read(partnerRepositoryProvider);
    return repo.getPartners(city: _selectedCity?.cityName);
  }

  Future<void> _pickCity() async {
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
        _partnersFuture = _loadPartners();
      });
    }
  }

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
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _partnersFuture = _loadPartners();
              });
              await _partnersFuture;
            },
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
                FutureBuilder<List<PartnerModel>>(
                  future: _partnersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _buildError(_humanError(snapshot.error));
                    }
                    final partners = snapshot.data ?? [];
                    if (partners.isEmpty) {
                      return _buildEmptyState();
                    }
                    return Column(
                      children: partners
                          .map((p) => _PartnerCard(partner: p))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return InkWell(
      onTap: _pickCity,
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
        borderRadius: BorderRadius.circular(16.r),
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
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Text(
            tr('driver_profile.business_page.error_title'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _partnersFuture = _loadPartners();
              });
            },
            child: Text(tr('common.retry')),
          ),
        ],
      ),
    );
  }

  String _humanError(Object? error) {
    if (error is ApiException) {
      return error.message;
    }
    return error?.toString() ?? tr('repository.partner.fetch_error');
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({required this.partner});

  final PartnerModel partner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              partner.companyName,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                _Tag(text: partner.activityDisplay),
                SizedBox(width: 8.w),
                _Tag(text: partner.city),
                SizedBox(width: 8.w),
                _Tag(text: partner.countriesDisplay),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              partner.companyDescription,
              style: TextStyle(fontSize: 13.5.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 18.w, color: Colors.grey[700]),
                SizedBox(width: 6.w),
                Text(partner.phone, style: TextStyle(fontSize: 13.5.sp)),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 18.w, color: Colors.grey[700]),
                SizedBox(width: 6.w),
                Text(partner.email, style: TextStyle(fontSize: 13.5.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F9),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5.sp, color: Colors.black87),
      ),
    );
  }
}
