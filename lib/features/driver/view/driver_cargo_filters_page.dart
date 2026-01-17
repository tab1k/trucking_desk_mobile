import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/driver/providers/saved_routes_provider.dart';
import 'package:fura24.kz/features/driver/domain/models/driver_cargo_filters.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:fura24.kz/features/transport/data/vehicle_type_options.dart';
import 'package:fura24.kz/shared/widgets/app_date_picker.dart';

class DriverCargoFiltersPage extends ConsumerStatefulWidget {
  const DriverCargoFiltersPage({super.key, required this.initialFilters});

  final DriverCargoFilters initialFilters;

  @override
  ConsumerState<DriverCargoFiltersPage> createState() =>
      _DriverCargoFiltersPageState();
}

class _DriverCargoFiltersPageState
    extends ConsumerState<DriverCargoFiltersPage> {
  late TextEditingController _departureController;
  late TextEditingController _destinationController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _vehicleTypeController;
  late TextEditingController _dateController;
  String _selectedVehicleType = '';
  int? _departurePointId;
  int? _destinationPointId;
  bool _onlyWithCall = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _departureController = TextEditingController(
      text: widget.initialFilters.departureCity,
    );
    _destinationController = TextEditingController(
      text: widget.initialFilters.destinationCity,
    );
    _minAmountController = TextEditingController(
      text: _formatNumber(widget.initialFilters.minAmount),
    );
    _maxAmountController = TextEditingController(
      text: _formatNumber(widget.initialFilters.maxAmount),
    );
    _selectedVehicleType = widget.initialFilters.vehicleType;
    _onlyWithCall = widget.initialFilters.onlyWithCall;
    _departurePointId = widget.initialFilters.departurePointId;
    _destinationPointId = widget.initialFilters.destinationPointId;
    _selectedDate = widget.initialFilters.transportationDate;
    _vehicleTypeController = TextEditingController(
      text: _selectedVehicleType.isEmpty
          ? ''
          : vehicleTypeOptions
                .firstWhere(
                  (option) => option.value == _selectedVehicleType,
                  orElse: () => vehicleTypeOptions.first,
                )
                .label,
    );
    _dateController = TextEditingController(
      text: _selectedDate != null ? _formatDate(_selectedDate!) : '',
    );
  }

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _vehicleTypeController.dispose();
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
        title: Text(tr('driver_cargo_filters.title')),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(tr('driver_cargo_filters.reset')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          children: [
            _LabeledField(
              label: tr('driver_cargo_filters.loading_city'),
              child: _SelectableField(
                controller: _departureController,
                hintText: tr('driver_cargo_filters.select_city'),
                icon: Icons.location_on_outlined,
                onTap: () => _pickCity(isDeparture: true),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(height: 12.h),
            _LabeledField(
              label: tr('driver_cargo_filters.unloading_city'),
              child: _SelectableField(
                controller: _destinationController,
                hintText: tr('driver_cargo_filters.select_city'),
                icon: Icons.flag_outlined,
                onTap: () => _pickCity(isDeparture: false),
              ),
            ),
            if (_departureController.text.isNotEmpty &&
                _destinationController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: GestureDetector(
                  onTap: _saveCurrentRoute,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 16.sp,
                        color: const Color(0xFF00B2FF),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        tr('driver_cargo_filters.save_route'),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF00B2FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            _LabeledField(
              label: tr('driver_cargo_filters.vehicle_type'),
              child: _SelectableField(
                controller: _vehicleTypeController,
                hintText: tr('driver_cargo_filters.any_vehicle'),
                icon: Icons.local_shipping_outlined,
                onTap: _pickVehicleType,
              ),
            ),
            SizedBox(height: 12.h),
            _LabeledField(
              label: tr('driver_cargo_filters.transport_date'),
              child: _SelectableField(
                controller: _dateController,
                hintText: tr('driver_cargo_filters.any_date'),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
                onClear: _selectedDate != null ? _clearDate : null,
              ),
            ),
            SizedBox(height: 12.h),
            _buildAmountRow(),
            SizedBox(height: 15.h),
            SwitchListTile.adaptive(
              value: _onlyWithCall,
              onChanged: (value) => setState(() => _onlyWithCall = value),
              tileColor: Colors.grey[100], // Серый фон
              shape: RoundedRectangleBorder(
                // Закругление углов
                borderRadius: BorderRadius.circular(12),
              ),
              title: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  tr('driver_cargo_filters.only_with_call'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              subtitle: Container(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  tr('driver_cargo_filters.only_with_call_subtitle'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: FilledButton(
            onPressed: _apply,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Text(tr('driver_cargo_filters.show_announcements')),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow() {
    return Row(
      children: [
        Expanded(
          child: _LabeledField(
            label: tr('driver_cargo_filters.cost_from'),
            child: TextField(
              controller: _minAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                hintText: '0',
                icon: Icons.currency_exchange,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _LabeledField(
            label: tr('driver_cargo_filters.cost_to'),
            child: TextField(
              controller: _maxAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                hintText: '0',
                icon: Icons.currency_exchange,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCurrentRoute() async {
    final dep = _departureController.text.trim();
    final dest = _destinationController.text.trim();
    if (dep.isEmpty || dest.isEmpty) return;

    try {
      await ref
          .read(savedRoutesProvider(null).notifier)
          .create(departureCityName: dep, destinationCityName: dest);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('driver_cargo_filters.route_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('driver_cargo_filters.save_error', args: [e.toString()]),
          ),
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _departureController.clear();
      _destinationController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _selectedVehicleType = '';
      _vehicleTypeController.clear();
      _departurePointId = null;
      _destinationPointId = null;
      _onlyWithCall = false;
      _selectedDate = null;
      _dateController.clear();
    });
  }

  void _apply() {
    final filters = DriverCargoFilters(
      departureCity: _departureController.text.trim(),
      destinationCity: _destinationController.text.trim(),
      vehicleType: _selectedVehicleType,
      minAmount: _parseDouble(_minAmountController.text),
      maxAmount: _parseDouble(_maxAmountController.text),
      onlyWithCall: _onlyWithCall,
      departurePointId: _departurePointId,
      destinationPointId: _destinationPointId,
      transportationDate: _selectedDate,
    );
    Navigator.of(context).pop(filters);
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    return value.toString();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  double? _parseDouble(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Future<void> _pickCity({required bool isDeparture}) async {
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
          child: LocationPickerSheet(
            title: isDeparture
                ? tr('driver_cargo_filters.loading_city')
                : tr('driver_cargo_filters.unloading_city'),
          ),
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      final city = selected.location.cityName;
      if (isDeparture) {
        _departureController.text = city;
        _departurePointId = selected.location.id;
      } else {
        _destinationController.text = city;
        _destinationPointId = selected.location.id;
      }
    });
  }

  Future<void> _pickVehicleType() async {
    final result = await _pickListOption<String>(
      title: 'Тип транспорта',
      currentValue: _selectedVehicleType,
      options: [
        const _BottomSheetOption(
          label: 'driver_cargo_filters.any_vehicle',
          value: '',
        ),
        ...vehicleTypeOptions.map(
          (option) =>
              _BottomSheetOption(label: option.label, value: option.value),
        ),
      ],
    );
    if (result == null) return;
    setState(() {
      _selectedVehicleType = result;
      if (result.isEmpty) {
        _vehicleTypeController.clear();
      } else {
        final label = vehicleTypeOptions
            .firstWhere(
              (option) => option.value == result,
              orElse: () => vehicleTypeOptions.first,
            )
            .label;
        _vehicleTypeController.text = label;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final selected = await showAppDatePicker(
      context,
      title: tr('driver_cargo_filters.transport_date'),
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected == null) return;
    setState(() {
      _selectedDate = selected;
      _dateController.text = _formatDate(selected);
    });
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _dateController.clear();
    });
  }

  Future<T?> _pickListOption<T>({
    required String title,
    required T currentValue,
    required List<_BottomSheetOption<T>> options,
  }) {
    final height = (MediaQuery.of(context).size.height * 0.65).clamp(
      320.0,
      520.0,
    );
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    height: 4.h,
                    width: 48.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
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
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.grey[600],
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  Expanded(
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option.value == currentValue;
                        return ListTile(
                          title: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({required String hintText, IconData? icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500]) : null,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        child,
      ],
    );
  }
}

class _SelectableField extends StatelessWidget {
  const _SelectableField({
    required this.controller,
    required this.hintText,
    required this.onTap,
    this.icon,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500]) : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
        suffixIcon: _buildSuffix(),
      ),
    );
  }

  Widget _buildSuffix() {
    if (onClear != null && controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: onClear,
      );
    }
    return const Icon(Icons.keyboard_arrow_down_rounded);
  }
}

class _BottomSheetOption<T> {
  const _BottomSheetOption({required this.label, required this.value});
  final String label;
  final T value;
}
