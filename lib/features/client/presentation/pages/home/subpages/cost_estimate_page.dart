import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';

class CostEstimatePage extends ConsumerStatefulWidget {
  const CostEstimatePage({super.key});

  @override
  ConsumerState<CostEstimatePage> createState() => _CostEstimatePageState();
}

class _CostEstimatePageState extends ConsumerState<CostEstimatePage> {
  final _loadingPointController = TextEditingController();
  final _unloadingPointController = TextEditingController();
  final _fuelConsumptionController = TextEditingController();
  final _fuelPriceController = TextEditingController();

  LocationModel? _departure;
  LocationModel? _destination;
  bool _isCalculating = false;
  String? _error;
  RouteInfo? _routeInfo;

  @override
  void initState() {
    super.initState();
    _fuelConsumptionController.addListener(_onInputsUpdated);
    _fuelPriceController.addListener(_onInputsUpdated);
  }

  @override
  void dispose() {
    _loadingPointController.dispose();
    _unloadingPointController.dispose();
    _fuelConsumptionController.dispose();
    _fuelPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              tr('cost_estimate.title'),
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      _buildLocationField(
                        label: tr('cost_estimate.loading_point'),
                        controller: _loadingPointController,
                        onTap: () => _pickLocation(isDeparture: true),
                      ),
                      SizedBox(height: 12.h),
                      _buildLocationField(
                        label: tr('cost_estimate.unloading_point'),
                        controller: _unloadingPointController,
                        onTap: () => _pickLocation(isDeparture: false),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              label: tr('cost_estimate.fuel_consumption'),
                              controller: _fuelConsumptionController,
                              icon: Icons.local_gas_station_outlined,
                              suffix: tr('cost_estimate.fuel_consumption_suffix'),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildNumberField(
                              label: tr('cost_estimate.fuel_price'),
                              controller: _fuelPriceController,
                              icon: Icons.attach_money_rounded,
                              suffix: tr('cost_estimate.fuel_price_suffix'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      _buildResultCard(theme),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B2FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: _isCalculating ? null : _calculateRoute,
                    child: Text(
                      _isCalculating
                          ? tr('cost_estimate.button_loading')
                          : tr('cost_estimate.button_calculate'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildResultCard(ThemeData theme) {
    final consumption = _parsePositiveDouble(_fuelConsumptionController.text);
    final fuelPrice = _parsePositiveDouble(_fuelPriceController.text);

    if (_error != null) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
        ),
      );
    }

    if (_routeInfo == null) {
      return Text(
        tr('cost_estimate.prompt'),
        style: theme.textTheme.bodyMedium,
      );
    }

    if (consumption == null || fuelPrice == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FBFF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF00B2FF).withOpacity(0.15)),
        ),
        child: Text(
          tr('cost_estimate.prompt_fuel'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.blueGrey[700],
          ),
        ),
      );
    }

    final distanceKm = _routeInfo!.distance / 1000;
    final duration = _formatDuration(_routeInfo!.duration);
    final estimatedCost = _calculateCost(
      distanceMeters: _routeInfo!.distance,
      fuelConsumptionPer100Km: consumption,
      fuelPricePerLiter: fuelPrice,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBFF),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFF00B2FF).withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('cost_estimate.result_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 6.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteLine(
                    label: tr('cost_estimate.from'),
                    value: _departure?.cityName ?? '',
                  ),
                  SizedBox(height: 6.h),
                  _RouteLine(
                    label: tr('cost_estimate.to'),
                    value: _destination?.cityName ?? '',
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  _InfoChip(
                    label: tr('cost_estimate.distance_short'),
                    value: '${distanceKm.toStringAsFixed(1)} км',
                  ),
                  _InfoChip(
                    label: tr('cost_estimate.duration_short'),
                    value: duration,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Divider(color: Colors.grey[200]),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  label: tr('cost_estimate.result_consumption'),
                  value:
                      '${consumption.toStringAsFixed(1)} ${tr('cost_estimate.fuel_consumption_suffix')}',
                ),
              ),
              Expanded(
                child: _InfoRow(
                  label: tr('cost_estimate.result_price'),
                  value: '${fuelPrice.toStringAsFixed(1)} ${tr('cost_estimate.fuel_price_suffix')}',
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00B2FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('cost_estimate.result_cost'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${estimatedCost.toStringAsFixed(2)} ₸',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF00A1E9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(
          Icons.location_on_outlined,
          size: 20,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF00B2FF), width: 1.4),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        hintText: label,
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF00B2FF), width: 1.4),
        ),
      ),
    );
  }

  Future<void> _pickLocation({required bool isDeparture}) async {
    final selected = await showModalBottomSheet<LocationPickerSelection>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
              child: LocationPickerSheet(
                title:
                    isDeparture
                        ? tr('cost_estimate.picker_loading')
                        : tr('cost_estimate.picker_unloading'),
              ),
            ),
          ),
    );
    if (selected == null) return;
    setState(() {
      if (isDeparture) {
        _departure = selected.location;
        _loadingPointController.text = selected.location.cityName;
      } else {
        _destination = selected.location;
        _unloadingPointController.text = selected.location.cityName;
      }
      _routeInfo = null;
      _error = null;
    });
  }

  Future<void> _calculateRoute() async {
    if (_departure == null || _destination == null) {
      setState(() {
        _error = tr('cost_estimate.error_select_points');
      });
      return;
    }
    final consumption = _parsePositiveDouble(_fuelConsumptionController.text);
    if (consumption == null) {
      setState(() {
        _error = tr('cost_estimate.error_invalid_consumption');
      });
      return;
    }
    final fuelPrice = _parsePositiveDouble(_fuelPriceController.text);
    if (fuelPrice == null) {
      setState(() {
        _error = tr('cost_estimate.error_invalid_price');
      });
      return;
    }
    setState(() {
      _isCalculating = true;
      _error = null;
    });
    final lon1 = _departure!.longitude;
    final lat1 = _departure!.latitude;
    final lon2 = _destination!.longitude;
    final lat2 = _destination!.latitude;
    if (lon1 == null || lat1 == null || lon2 == null || lat2 == null) {
      setState(() {
        _isCalculating = false;
        _error = tr('cost_estimate.error_no_coords');
      });
      return;
    }
    try {
      final dio = Dio();
      final url =
          'http://router.project-osrm.org/route/v1/driving/$lon1,$lat1;$lon2,$lat2';
      final response = await dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {'overview': 'false'},
      );
      final routes = response.data?['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) {
        throw Exception('Маршрут не найден');
      }
      final route = routes.first as Map<String, dynamic>;
      final distance = (route['distance'] as num?)?.toDouble() ?? 0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0;
      final steps = _extractSteps(route['legs'] as List<dynamic>?);
      setState(() {
        _routeInfo = RouteInfo(
          distance: distance,
          duration: duration,
          steps: steps,
        );
        _isCalculating = false;
      });
    } catch (error) {
      setState(() {
        _isCalculating = false;
        _error = tr(
          'cost_estimate.error_request_failed',
          args: [error.toString()],
        );
      });
    }
  }

  List<String>? _extractSteps(List<dynamic>? legs) {
    if (legs == null || legs.isEmpty) return null;
    final steps = <String>[];
    for (final leg in legs) {
      final stepsData = leg['steps'] as List<dynamic>? ?? [];
      for (final step in stepsData) {
        final name = step['name'] as String?;
        if (name != null && name.isNotEmpty) {
          steps.add(name);
        }
      }
    }
    return steps.isEmpty ? null : steps;
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours ч ${minutes.toString().padLeft(2, '0')} мин';
    }
    return '$minutes мин';
  }

  double _calculateCost({
    required double distanceMeters,
    required double fuelConsumptionPer100Km,
    required double fuelPricePerLiter,
  }) {
    final distanceKm = distanceMeters / 1000;
    final fuelUsed = distanceKm * (fuelConsumptionPer100Km / 100);
    return fuelUsed * fuelPricePerLiter;
  }

  double? _parsePositiveDouble(String value) {
    final sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) return null;
    final parsed = double.tryParse(sanitized);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _onInputsUpdated() {
    if (_routeInfo != null) {
      setState(() {});
      return;
    }
    if (_error == tr('cost_estimate.error_invalid_consumption') ||
        _error == tr('cost_estimate.error_invalid_price')) {
      setState(() {
        _error = null;
      });
    }
  }
}

class RouteInfo {
  RouteInfo({required this.distance, required this.duration, this.steps});

  final double distance;
  final double duration;
  final List<String>? steps;
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF00B2FF).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.only(top: 6.h),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF00B2FF),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
