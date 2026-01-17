import 'dart:async';
import 'dart:math' as math; // For simple Haversine fallback

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';

class DriverExpensesPage extends ConsumerStatefulWidget {
  const DriverExpensesPage({super.key});

  @override
  ConsumerState<DriverExpensesPage> createState() => _DriverExpensesPageState();
}

class _DriverExpensesPageState extends ConsumerState<DriverExpensesPage> {
  final _depController = TextEditingController();
  final _destController = TextEditingController();
  final _consumptionController = TextEditingController();
  final _priceController = TextEditingController();

  LocationModel? _departure;
  LocationModel? _destination;

  bool _isCalculating = false;
  String? _error;
  _CalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _consumptionController.addListener(_clearError);
    _priceController.addListener(_clearError);
  }

  @override
  void dispose() {
    _depController.dispose();
    _destController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.only(left: 10.w),
            child: Text(
              tr('driver_expenses.title'),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('driver_expenses.subtitle'),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      _buildField(
                        label: tr('driver_expenses.from'),
                        controller: _depController,
                        readOnly: true,
                        onTap: () => _pickLocation(true),
                        hint: tr('driver_expenses.select_city'),
                      ),
                      SizedBox(height: 16.h),
                      _buildField(
                        label: tr('driver_expenses.to'),
                        controller: _destController,
                        readOnly: true,
                        onTap: () => _pickLocation(false),
                        hint: tr('driver_expenses.select_city'),
                      ),

                      SizedBox(height: 16.h),
                      _buildField(
                        label: tr('driver_expenses.consumption'),
                        controller: _consumptionController,
                        inputType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hint: 'driver_expenses.hint_consumption'.tr(),
                      ),

                      SizedBox(height: 16.h),
                      _buildField(
                        label: tr('driver_expenses.price'),
                        controller: _priceController,
                        inputType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hint: 'driver_expenses.hint_price'.tr(),
                      ),

                      SizedBox(height: 24.h),

                      if (_result != null) _buildResultCard(),
                      if (_error != null)
                        Container(
                          margin: EdgeInsets.only(top: 24.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16.w),
                child: ElevatedButton(
                  onPressed: _isCalculating ? null : _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF3B82F6,
                    ), // Blue button like web
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _isCalculating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          tr('driver_expenses.calculate'),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? inputType,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: inputType,
          inputFormatters: inputType != null
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF8FAFC), // Slight grey bg
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7), // Green 50 (Tailwind approx) - Green bg
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF86EFAC)), // Green 300 border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('driver_expenses.fuel_cost'),
            style: TextStyle(
              color: const Color(0xFF15803D), // Green 700
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${r.totalCost.toStringAsFixed(0)} ₸',
            style: TextStyle(
              color: const Color(0xFF15803D),
              fontSize: 32.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          _buildResultRow(
            'driver_expenses.result_distance'.tr(),
            '~${r.distance.round()} км',
          ),
          _buildResultRow(
            'driver_expenses.result_consumption'.tr(),
            '${r.consumption} л/100км',
          ),
          _buildResultRow(
            'driver_expenses.result_fuel'.tr(),
            '${r.fuelNeeded.toStringAsFixed(1)} л',
          ),

          SizedBox(height: 16.h),
          Text(
            tr('driver_expenses.disclaimer'),
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF15803D).withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF15803D).withOpacity(0.8),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocation(bool isDep) async {
    final selected = await showModalBottomSheet<LocationPickerSelection>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          child: LocationPickerSheet(title: isDep ? 'Откуда' : 'Куда'),
        ),
      ),
    );

    if (selected != null) {
      if (mounted) {
        setState(() {
          if (isDep) {
            _departure = selected.location;
            _depController.text = selected.location.cityName;
          } else {
            _destination = selected.location;
            _destController.text = selected.location.cityName;
          }
          _result = null; // Clear prev result
        });
      }
    }
  }

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();

    if (_departure == null || _destination == null) {
      setState(() => _error = 'driver_expenses.error_select_cities'.tr());
      return;
    }

    final cons = double.tryParse(
      _consumptionController.text.replaceAll(',', '.'),
    );
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));

    if (cons == null || price == null) {
      setState(() => _error = 'driver_expenses.error_invalid_input'.tr());
      return;
    }

    setState(() {
      _isCalculating = true;
      _error = null;
    });

    double? distanceKm;

    // 1. Try OSRM
    try {
      final dio = Dio();
      final url =
          'http://router.project-osrm.org/route/v1/driving/'
          '${_departure!.longitude},${_departure!.latitude};'
          '${_destination!.longitude},${_destination!.latitude}';

      final response = await dio
          .get<Map<String, dynamic>>(
            url,
            queryParameters: {'overview': 'false'},
          )
          .timeout(const Duration(seconds: 5)); // Fast timeout

      final routes = response.data?['routes'] as List<dynamic>?;
      if (routes != null && routes.isNotEmpty) {
        final distMeters = (routes.first['distance'] as num).toDouble();
        distanceKm = distMeters / 1000;
      }
    } catch (e) {
      // OSRM Failed, proceed to fallback
      // debugPrint('OSRM Failed: $e');
    }

    // 2. Fallback: Haversine * 1.2
    if (distanceKm == null) {
      if (_departure!.latitude == null || _destination!.latitude == null) {
        setState(() {
          _isCalculating = false;
          _error = 'driver_expenses.error_coords'.tr();
        });
        return;
      }

      final distRaw = _calculateDistance(
        _departure!.latitude!,
        _departure!.longitude!,
        _destination!.latitude!,
        _destination!.longitude!,
      );
      distanceKm = distRaw * 1.2; // +20% buffer
    }

    // Final Calc
    // Fuel = (Distance / 100) * Consumption
    final fuelNeeded = (distanceKm / 100) * cons;
    final totalCost = fuelNeeded * price;

    if (mounted) {
      setState(() {
        _isCalculating = false;
        _result = _CalculationResult(
          distance: distanceKm!,
          fuelNeeded: fuelNeeded,
          totalCost: totalCost,
          consumption: cons,
        );
      });
    }
  }

  // Haversine Formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}

class _CalculationResult {
  final double distance;
  final double fuelNeeded;
  final double totalCost;
  final double consumption;

  _CalculationResult({
    required this.distance,
    required this.fuelNeeded,
    required this.totalCost,
    required this.consumption,
  });
}
