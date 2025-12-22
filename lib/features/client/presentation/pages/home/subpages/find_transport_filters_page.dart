import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement_filters.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:fura24.kz/features/transport/data/vehicle_type_options.dart';
import 'package:fura24.kz/shared/widgets/app_date_picker.dart';

class _DropdownOption<T> {
  const _DropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

const _loadingTypeOptions = [
  _DropdownOption(value: 'ANY', label: 'find_transport.filters.loading.any'),
  _DropdownOption(value: 'BACK', label: 'find_transport.filters.loading.back'),
  _DropdownOption(value: 'TOP', label: 'find_transport.filters.loading.top'),
  _DropdownOption(value: 'SIDE', label: 'find_transport.filters.loading.side'),
  _DropdownOption(
    value: 'BACK_SIDE_TOP',
    label: 'find_transport.filters.loading.back_side_top',
  ),
];

final _vehicleOptions = vehicleTypeOptions
    .map(
      (option) => _DropdownOption<String>(
        value: option.value,
        label: 'vehicle_type.${option.value.toLowerCase()}',
      ),
    )
    .toList(growable: false);

class FindTransportFiltersPage extends StatefulWidget {
  const FindTransportFiltersPage({super.key, required this.initialFilters});

  final DriverAnnouncementFilters initialFilters;

  @override
  State<FindTransportFiltersPage> createState() =>
      _FindTransportFiltersPageState();
}

class _FindTransportFiltersPageState extends State<FindTransportFiltersPage> {
  final _loadingPointController = TextEditingController();
  final _unloadingPointController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _loadingTypeController = TextEditingController();
  final _weightFromController = TextEditingController();
  final _weightToController = TextEditingController();
  final _volumeFromController = TextEditingController();
  final _volumeToController = TextEditingController();
  final _dateController = TextEditingController();
  String _selectedVehicleValue = '';
  String _selectedLoadingValue = '';

  LocationModel? _selectedLoadingLocation;
  LocationModel? _selectedUnloadingLocation;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _loadingPointController.text = filters.departureCity;
    _unloadingPointController.text = filters.destinationCity;
    _selectedVehicleValue = _normalizeVehicleValue(filters.vehicleType);
    _selectedLoadingValue = _normalizeLoadingValue(filters.loadingType);
    _vehicleTypeController.text = _translateVehicleValue(_selectedVehicleValue);
    _loadingTypeController.text = _translateLoadingValue(_selectedLoadingValue);
    _weightFromController.text = _formatNumber(filters.weightFrom);
    _weightToController.text = _formatNumber(filters.weightTo);
    _volumeFromController.text = _formatNumber(filters.volumeFrom);
    _volumeToController.text = _formatNumber(filters.volumeTo);
    _selectedDate = filters.createdDate;
    if (_selectedDate != null) {
      _dateController.text = _formatDate(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _loadingPointController.dispose();
    _unloadingPointController.dispose();
    _vehicleTypeController.dispose();
    _loadingTypeController.dispose();
    _weightFromController.dispose();
    _weightToController.dispose();
    _volumeFromController.dispose();
    _volumeToController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(tr('find_transport.filters.title')),
        actions: [TextButton(onPressed: _reset, child: Text(tr('common.reset')))],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          children: [
            _buildLocationField(
              controller: _loadingPointController,
              label: tr('find_transport.filters.departure'),
              icon: Icons.location_on_outlined,
              onTap: () => _pickLocation(isLoading: true),
            ),
            SizedBox(height: 12.h),
            _buildLocationField(
              controller: _unloadingPointController,
              label: tr('find_transport.filters.destination'),
              icon: Icons.flag_outlined,
              onTap: () => _pickLocation(isLoading: false),
            ),
            SizedBox(height: 12.h),
            _buildSelectionField(
              label: tr('find_transport.filters.vehicle'),
              value:
                  _vehicleTypeController.text.isEmpty
                      ? tr('find_transport.filters.vehicle_any')
                      : _vehicleTypeController.text,
              onTap:
                  () => _showSelectionSheet(
                    title: tr('find_transport.filters.vehicle'),
                    options: _vehicleOptions,
                    selectedValue: _selectedVehicleValue,
                    onSelected: (option) {
                      _selectedVehicleValue = option.value;
                      _vehicleTypeController.text = tr(option.label);
                    },
                  ),
            ),
            SizedBox(height: 12.h),
            _buildSelectionField(
              label: tr('find_transport.filters.loading_title'),
              value:
                  _loadingTypeController.text.isEmpty
                      ? tr('find_transport.filters.loading.any')
                      : _loadingTypeController.text,
              onTap:
                  () => _showSelectionSheet(
                    title: tr('find_transport.filters.loading_title'),
                    options: _loadingTypeOptions,
                    selectedValue: _selectedLoadingValue,
                    onSelected: (option) {
                      _selectedLoadingValue = option.value;
                      _loadingTypeController.text = tr(option.label);
                    },
                  ),
            ),
            SizedBox(height: 16.h),
            _buildRangeRow(
              leftController: _weightFromController,
              rightController: _weightToController,
              leftLabel: tr('find_transport.filters.weight_from'),
              rightLabel: tr('find_transport.filters.weight_to'),
              icon: Icons.scale_outlined,
            ),
            SizedBox(height: 12.h),
            _buildRangeRow(
              leftController: _volumeFromController,
              rightController: _volumeToController,
              leftLabel: tr('find_transport.filters.volume_from'),
              rightLabel: tr('find_transport.filters.volume_to'),
              icon: Icons.aspect_ratio_outlined,
            ),
            SizedBox(height: 12.h),
            _buildDateField(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: SizedBox(
            height: 52.h,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                tr('find_transport.filters.apply'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
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

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.grey[500],
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
    );
  }

  Widget _buildRangeRow({
    required TextEditingController leftController,
    required TextEditingController rightController,
    required String leftLabel,
    required String rightLabel,
    required IconData icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: leftController,
            keyboardType: TextInputType.number,
            decoration: _rangeDecoration(leftLabel, icon: icon),
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: TextField(
            controller: rightController,
            keyboardType: TextInputType.number,
            decoration: _rangeDecoration(rightLabel),
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  InputDecoration _rangeDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: Colors.grey[500]) : null,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      onTap: _pickDate,
      decoration: InputDecoration(
        hintText: tr('find_transport.filters.date'),
        prefixIcon: Icon(
          Icons.calendar_today_outlined,
          size: 20,
          color: Colors.grey[500],
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: _selectedDate != null ? _clearDate : null,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
    );
  }

  Future<void> _pickLocation({required bool isLoading}) async {
    final selected = await showModalBottomSheet<LocationPickerSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Material(
                color: Colors.white,
                child: LocationPickerSheet(
                  title: tr('find_transport_filters.pick_city'),
                ),
              ),
            ),
      );
      },
    );
    if (selected == null) return;
    setState(() {
      final location = selected.location;
      if (isLoading) {
        _selectedLoadingLocation = location;
        _loadingPointController.text = location.cityName;
      } else {
        _selectedUnloadingLocation = location;
        _unloadingPointController.text = location.cityName;
      }
    });
  }

  Future<void> _pickDate() async {
      final picked = await showAppDatePicker(
        context,
        firstDate: DateTime.now(),
        title: tr('find_transport_filters.request_date'),
      );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _dateController.clear();
    });
  }

  void _reset() {
    setState(() {
      _selectedLoadingLocation = null;
      _selectedUnloadingLocation = null;
      _loadingPointController.clear();
      _unloadingPointController.clear();
      _vehicleTypeController.clear();
      _loadingTypeController.clear();
      _selectedVehicleValue = '';
      _selectedLoadingValue = '';
      _weightFromController.clear();
      _weightToController.clear();
      _volumeFromController.clear();
      _volumeToController.clear();
      _selectedDate = null;
      _dateController.clear();
    });
  }

  void _apply() {
    final filters = DriverAnnouncementFilters(
      departureCity: _loadingPointController.text,
      destinationCity: _unloadingPointController.text,
      vehicleType: _selectedVehicleValue,
      loadingType: _selectedLoadingValue,
      weightFrom: _parseDouble(_weightFromController.text),
      weightTo: _parseDouble(_weightToController.text),
      volumeFrom: _parseDouble(_volumeFromController.text),
      volumeTo: _parseDouble(_volumeToController.text),
      createdDate: _selectedDate,
    );
    Navigator.of(context).pop(filters);
  }

  String _normalizeVehicleValue(String value) {
    if (value.isEmpty) return '';
    final upper = value.toUpperCase();
    for (final option in _vehicleOptions) {
      if (option.value == upper) return option.value;
    }
    for (final option in _vehicleOptions) {
      final translated = tr(option.label);
      if (translated.toLowerCase() == value.toLowerCase()) {
        return option.value;
      }
    }
    return upper;
  }

  String _normalizeLoadingValue(String value) {
    if (value.isEmpty) return '';
    final upper = value.toUpperCase();
    for (final option in _loadingTypeOptions) {
      if (option.value == upper) return option.value;
    }
    const prefix = 'find_transport.filters.loading.';
    if (value.startsWith(prefix)) {
      final suffix = value.substring(prefix.length).toUpperCase();
      for (final option in _loadingTypeOptions) {
        if (option.value == suffix) return option.value;
      }
    }
    for (final option in _loadingTypeOptions) {
      final translated = tr(option.label);
      if (translated.toLowerCase() == value.toLowerCase()) {
        return option.value;
      }
    }
    return upper;
  }

  String _translateVehicleValue(String value) {
    if (value.isEmpty) return '';
    final key = 'vehicle_type.${value.toLowerCase()}';
    final translated = tr(key);
    return translated == key ? value : translated;
  }

  String _translateLoadingValue(String value) {
    if (value.isEmpty) return '';
    final key = 'find_transport.filters.loading.${value.toLowerCase()}';
    final translated = tr(key);
    return translated == key ? value : translated;
  }

  double? _parseDouble(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    return value.toString();
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year}';
  }

  Future<void> _showSelectionSheet({
    required String title,
    required List<_DropdownOption<String>> options,
    required String? selectedValue,
    required ValueChanged<_DropdownOption<String>> onSelected,
  }) async {
    final picked = await showModalBottomSheet<_DropdownOption<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: math.min(MediaQuery.of(context).size.height * 0.55, 420.h),
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      width: 48.w,
                      height: 4.h,
                      margin: EdgeInsets.only(top: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.only(top: 8.h),
                        itemCount: options.length,
                        separatorBuilder:
                            (_, __) =>
                                Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = option.value == selectedValue;
                          return ListTile(
                            title: Text(
                              tr(option.label),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[500],
                            ),
                            onTap: () => Navigator.of(context).pop(option),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }
}
