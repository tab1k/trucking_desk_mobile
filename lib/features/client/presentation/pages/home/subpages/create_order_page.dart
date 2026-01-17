import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';
import 'package:fura24.kz/features/client/presentation/providers/create_order_provider.dart';
import 'package:fura24.kz/features/client/presentation/providers/my_orders_provider.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:fura24.kz/features/transport/data/vehicle_type_options.dart';
import 'package:fura24.kz/shared/widgets/app_date_picker.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:fura24.kz/shared/widgets/address_autocomplete_field.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key, this.editingOrder, this.prefilledOrder})
    : assert(
        editingOrder == null || prefilledOrder == null,
        'Provide either editingOrder or prefilledOrder, not both.',
      );

  final OrderDetail? editingOrder;
  final OrderDetail? prefilledOrder;

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    4,
    (_) => GlobalKey<FormState>(),
  );
  final List<String> _stepTitles = const [
    'create_order.steps.route',
    'create_order.steps.transport',
    'create_order.steps.payment',
    'create_order.steps.cargo',
  ];
  final List<String> _stepDescriptions = const [
    'create_order.steps.route_desc',
    'create_order.steps.transport_desc',
    'create_order.steps.payment_desc',
    'create_order.steps.cargo_desc',
  ];

  static const int _maxPhotos = 6;

  int _currentStep = 0;
  DateTime? _selectedTransportationDate;
  String _selectedVehicleType = vehicleTypeOptions.first.value;
  String _selectedLoadingType = 'ANY';
  String _selectedPaymentType = 'CASH';
  String _selectedCurrency = 'KZT';
  LocationModel? _departureLocation;
  LocationModel? _destinationLocation;
  bool _departureSelectedOnMap = false;
  bool _destinationSelectedOnMap = false;
  String? _departureMapAddress;
  String? _destinationMapAddress;
  static const int _maxWaypoints = 5; // включая начало и конец
  final List<_WaypointStop> _midPoints = [];

  final _departurePointController = TextEditingController();
  final _departureAddressController = TextEditingController();
  final _destinationPointController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _transportDateController = TextEditingController();
  final _transportDurationController = TextEditingController();
  final _cargoNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _showPhoneToDrivers = true;

  bool get _isUrbanRoute {
    if (_departureLocation == null || _destinationLocation == null)
      return false;
    return _departureLocation!.cityName.trim().toLowerCase() ==
        _destinationLocation!.cityName.trim().toLowerCase();
  }

  bool get _requiresDepartureAddress =>
      _isUrbanRoute && !_departureSelectedOnMap;

  bool get _requiresDestinationAddress =>
      _isUrbanRoute && !_destinationSelectedOnMap;

  final List<_PickedPhoto> _selectedPhotos = [];
  final List<String> _existingPhotoUrls = [];
  final FocusNode _disabledFocusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  bool get _isEditing => widget.editingOrder != null;
  bool get _isRepeating => !_isEditing && widget.prefilledOrder != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFromDetail(widget.editingOrder!);
    } else if (_isRepeating) {
      _populateFromDetail(widget.prefilledOrder!, includePhotos: false);
    }
  }

  Widget build(BuildContext context) {
    final createOrderState = ref.watch(createOrderControllerProvider);
    final isSubmitting = createOrderState.isLoading;

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
          toolbarHeight: 72.h,
          titleSpacing: 0,
          centerTitle: false,
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
            padding: EdgeInsets.only(right: 16.w, left: 16.w),
            child: SizedBox(height: 8.h, child: _buildProgressStatus()),
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
                      if (_currentStep == 0) ...[
                        SizedBox(height: 8.h),
                        Text(
                          _isEditing
                              ? tr('create_order.edit_title')
                              : tr('create_order.title'),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          tr('create_order.subtitle'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ] else ...[
                        SizedBox(height: 24.h),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentStep),
                          child: _buildStepContent(context, _currentStep),
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
              _buildNavigationBar(isSubmitting),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLocation({required bool isDeparture}) async {
    final selected = await showModalBottomSheet<LocationPickerSelection>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          child: LocationPickerSheet(
            title: isDeparture
                ? tr('create_order.location.pick_departure')
                : tr('create_order.location.pick_destination'),
          ),
        ),
      ),
    );

    if (selected == null) return;

    setState(() {
      if (isDeparture) {
        _departureLocation = selected.location;
        _departurePointController.text = selected.location.cityName;
        _departureSelectedOnMap = selected.selectedOnMap;
        _departureMapAddress = selected.selectedOnMap
            ? selected.addressLabel
            : null;
        if (_departureSelectedOnMap) {
          _departureAddressController.clear();
        }
      } else {
        _destinationLocation = selected.location;
        _destinationPointController.text = selected.location.cityName;
        _destinationSelectedOnMap = selected.selectedOnMap;
        _destinationMapAddress = selected.selectedOnMap
            ? selected.addressLabel
            : null;
        if (_destinationSelectedOnMap) {
          _destinationAddressController.clear();
        }
      }
    });
  }

  Future<void> _pickMidLocation() async {
    if (_midPoints.length >= (_maxWaypoints - 2)) return;
    final selected = await showModalBottomSheet<LocationPickerSelection>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          child: LocationPickerSheet(
            title: tr('create_order.route_points.pick'),
          ),
        ),
      ),
    );
    if (selected == null) return;

    setState(() {
      _midPoints.add(_WaypointStop(location: selected.location));
    });
  }

  Widget _buildProgressStatus() {
    final progress = (_currentStep + 1) / _stepTitles.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6.h,
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B2FF)),
      ),
    );
  }

  void _populateFromDetail(OrderDetail detail, {bool includePhotos = true}) {
    _midPoints.clear();

    final waypoints = detail.waypoints;
    if (waypoints.length >= 2) {
      final first = waypoints.first;
      final last = waypoints.last;
      _departureLocation = first.location;
      _departurePointController.text = first.location.cityName;
      _destinationLocation = last.location;
      _destinationPointController.text = last.location.cityName;
      _departureAddressController.text = first.addressDetail ?? '';
      _destinationAddressController.text = last.addressDetail ?? '';
      if (waypoints.length > 2) {
        for (final wp in waypoints.sublist(1, waypoints.length - 1)) {
          _midPoints.add(
            _WaypointStop(
              location: wp.location,
              initialAddress: wp.addressDetail,
            ),
          );
        }
      }
    } else {
      _departureLocation = detail.departurePoint;
      _departurePointController.text = detail.departurePoint.cityName;
      _destinationLocation = detail.destinationPoint;
      _destinationPointController.text = detail.destinationPoint.cityName;
      _departureAddressController.text = detail.departureAddressDetail ?? '';
      _destinationAddressController.text =
          detail.destinationAddressDetail ?? '';
    }
    _selectedVehicleType = detail.vehicleType;
    _selectedLoadingType = detail.loadingType;
    _weightController.text = _formatDecimal(detail.weightTons);
    _volumeController.text = _formatDecimal(detail.volumeCubicMeters);
    _lengthController.text = _formatDecimal(detail.lengthMeters);
    _widthController.text = _formatDecimal(detail.widthMeters);
    _heightController.text = _formatDecimal(detail.heightMeters);
    _transportDateController.text = _formatDateForField(
      detail.transportationDate,
    );
    _selectedTransportationDate = detail.transportationDate;
    _transportDurationController.text =
        detail.transportationTermDays?.toString() ?? '';
    _selectedPaymentType = detail.paymentType;
    _cargoNameController.text = detail.cargoName;
    _amountController.text = _formatDecimal(detail.amount);
    _selectedCurrency = detail.currency;
    _notesController.text = detail.description ?? '';
    _showPhoneToDrivers = detail.showPhoneToDrivers;
    _existingPhotoUrls.clear();
    if (includePhotos) {
      _existingPhotoUrls.addAll(detail.photoUrls);
    }
  }

  String _formatDecimal(num? value) {
    if (value == null) return '';
    var text = value.toString();
    if (text.contains('.') && text.endsWith('0')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  String _formatDateForField(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Widget _buildNavigationBar(bool isSubmitting) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _stepTitles.length - 1;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, -4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            if (!isFirstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!, width: 1),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(tr('common.back')),
                ),
              ),
            if (!isFirstStep) SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async => _handleNext(isLastStep: isLastStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B2FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  isLastStep
                      ? (isSubmitting
                            ? tr('create_order.creating')
                            : tr('create_order.publish'))
                      : tr('common.next'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNext({required bool isLastStep}) async {
    FocusScope.of(context).unfocus();
    final formState = _formKeys[_currentStep].currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (isLastStep) {
      await _submitForm();
    } else {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0) return;
    setState(() {
      _currentStep -= 1;
    });
  }

  Widget _buildStepContent(BuildContext context, int step) {
    final theme = Theme.of(context);
    switch (step) {
      case 0:
        return _buildStepForm(
          step,
          children: [
            _buildLocationField(
              controller: _departurePointController,
              label: tr('create_order.form.route.departure_point'),
              onTap: () => _pickLocation(isDeparture: true),
            ),
            if (_departureSelectedOnMap && _departureMapAddress != null) ...[
              SizedBox(height: 4.h),
              _buildMapLocationHint(_departureMapAddress!),
            ],
            SizedBox(height: 12.h),
            AddressAutocompleteField(
              controller: _departureAddressController,
              label: tr('create_order.form.route.departure_address'),
              icon: Icons.home_outlined,
              isRequired: _requiresDepartureAddress,
              city: _departureLocation?.cityName,
            ),
            SizedBox(height: 12.h),
            _buildWaypointList(),
            SizedBox(height: 8.h),
            _buildLocationField(
              controller: _destinationPointController,
              label: tr('create_order.form.route.destination_point'),
              onTap: () => _pickLocation(isDeparture: false),
            ),
            if (_destinationSelectedOnMap &&
                _destinationMapAddress != null) ...[
              SizedBox(height: 4.h),
              _buildMapLocationHint(_destinationMapAddress!),
            ],
            SizedBox(height: 12.h),
            AddressAutocompleteField(
              controller: _destinationAddressController,
              label: tr('create_order.form.route.destination_address'),
              icon: Icons.location_city_outlined,
              isRequired: _requiresDestinationAddress,
              city: _destinationLocation?.cityName,
            ),
            if (_isUrbanRoute) ...[
              SizedBox(height: 12.h),
              _buildSameCityNote(theme),
            ],

            SizedBox(height: 10.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                tr('create_order.form.route.catalog_hint'),
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
              ),
            ),
          ],
        );
      case 1:
        return _buildStepForm(
          step,
          children: [
            _buildSelectionField(
              label: tr('create_order.form.transport.vehicle_type'),
              value: _labelForOption(_vehicleOptions, _selectedVehicleType),
              onTap: () => _pickOption<String>(
                title: tr('create_order.form.transport.vehicle_type'),
                options: _vehicleOptions,
                currentValue: _selectedVehicleType,
                onSelected: (value) =>
                    setState(() => _selectedVehicleType = value),
              ),
            ),
            SizedBox(height: 12.h),
            _buildSelectionField(
              label: tr('create_order.form.transport.loading_type'),
              value: _labelForOption(_loadingOptions, _selectedLoadingType),
              onTap: () => _pickOption<String>(
                title: tr('create_order.form.transport.loading_type'),
                options: _loadingOptions,
                currentValue: _selectedLoadingType,
                onSelected: (value) =>
                    setState(() => _selectedLoadingType = value),
              ),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _weightController,
              label: tr('create_order.form.transport.weight'),
              icon: Icons.scale_outlined,
              isRequired: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _volumeController,
              label: tr('create_order.form.transport.volume'),
              icon: Icons.aspect_ratio_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _lengthController,
                    label: tr('create_order.form.transport.length'),
                    icon: Icons.straighten,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _widthController,
                    label: tr('create_order.form.transport.width'),
                    icon: Icons.straighten,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: tr('create_order.form.transport.height'),
                    icon: Icons.height,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
        return _buildStepForm(
          step,
          children: [
            _buildTextField(
              controller: _transportDateController,
              label: tr('create_order.form.payment.transport_date'),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
              readOnly: true,
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _transportDurationController,
              label: tr('create_order.form.payment.transport_term'),
              icon: Icons.access_time_outlined,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24.h),
            _buildSelectionField(
              label: tr('create_order.form.payment.payment_type'),
              value: _labelForOption(_paymentTypeOptions, _selectedPaymentType),
              onTap: () => _pickOption<String>(
                title: tr('create_order.form.payment.payment_type'),
                options: _paymentTypeOptions,
                currentValue: _selectedPaymentType,
                onSelected: (value) =>
                    setState(() => _selectedPaymentType = value),
              ),
            ),
          ],
        );
      case 3:
        return _buildStepForm(
          step,
          children: [
            _buildSectionTitle(tr('create_order.form.cargo.details_title')),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _cargoNameController,
              label: tr('create_order.form.cargo.name'),
              icon: Icons.inventory_2_outlined,
              isRequired: true,
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _amountController,
                    label: tr('create_order.form.cargo.amount'),
                    icon: Icons.attach_money_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    isRequired: true,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 1,
                  child: _buildSelectionField(
                    label: tr('create_order.form.cargo.currency'),
                    value: _labelForOption(_currencyOptions, _selectedCurrency),
                    onTap: () => _pickOption<String>(
                      title: tr('create_order.form.cargo.currency'),
                      options: _currencyOptions,
                      currentValue: _selectedCurrency,
                      onSelected: (value) =>
                          setState(() => _selectedCurrency = value),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle(tr('create_order.form.cargo.photos')),
            SizedBox(height: 12.h),
            _buildPhotoPicker(),
            SizedBox(height: 8.h),
            Text(
              tr('create_order.form.cargo.photos_hint'),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle(tr('create_order.form.cargo.additional')),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _notesController,
              label: tr('create_order.form.cargo.note'),
              icon: Icons.note_outlined,
              maxLines: 3,
            ),
            SizedBox(height: 14.h),
            _buildContactVisibilityTile(),
            SizedBox(height: 14.h),
            _buildSummaryCard(context),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepForm(int step, {required List<Widget> children}) {
    return Form(
      key: _formKeys[step],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              'create_order.step_counter',
              args: ['${step + 1}', '${_stepTitles.length}'],
            ),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            tr(_stepTitles[step]),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            tr(_stepDescriptions[step]),
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 24.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: '$label *',
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: CupertinoColors.systemGrey,
        ),
        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return tr('create_order.form.validation.select_city');
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: '$label${isRequired ? ' *' : ''}',
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: CupertinoColors.systemGrey,
        ),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
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
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return tr('create_order.form.validation.required');
              }
              return null;
            }
          : null,
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
                value,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSameCityNote(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18.w,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              tr('create_order.same_city_note'),
              style: TextStyle(
                fontSize: 12.5.sp,
                color: theme.colorScheme.primary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DropdownOption<String>> get _vehicleOptions => vehicleTypeOptions
      .map(
        (option) => _DropdownOption<String>(
          value: option.value,
          label: _vehicleLabel(option.value),
        ),
      )
      .toList(growable: false);

  List<_DropdownOption<String>> get _loadingOptions => [
    _DropdownOption(
      value: 'ANY',
      label: tr('create_order.filters.loading.any'),
    ),
    _DropdownOption(
      value: 'BACK',
      label: tr('create_order.filters.loading.back'),
    ),
    _DropdownOption(
      value: 'TOP',
      label: tr('create_order.filters.loading.top'),
    ),
    _DropdownOption(
      value: 'SIDE',
      label: tr('create_order.filters.loading.side'),
    ),
    _DropdownOption(
      value: 'BACK_SIDE_TOP',
      label: tr('create_order.filters.loading.back_side_top'),
    ),
  ];

  List<_DropdownOption<String>> get _paymentTypeOptions => [
    _DropdownOption(value: 'CASH', label: tr('create_order.payment_type.cash')),
    _DropdownOption(
      value: 'NON_CASH',
      label: tr('create_order.payment_type.non_cash'),
    ),
    _DropdownOption(value: 'CARD', label: tr('create_order.payment_type.card')),
  ];

  List<_DropdownOption<String>> get _currencyOptions => [
    _DropdownOption(value: 'KZT', label: tr('create_order.currency.kzt')),
    _DropdownOption(value: 'USD', label: tr('create_order.currency.usd')),
    _DropdownOption(value: 'EUR', label: tr('create_order.currency.eur')),
    _DropdownOption(value: 'RUB', label: tr('create_order.currency.rub')),
    _DropdownOption(value: 'KGS', label: tr('create_order.currency.kgs')),
  ];

  Widget _buildWaypointList() {
    final remaining = _maxWaypoints - 2 - _midPoints.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._midPoints.asMap().entries.map(
          (entry) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Column(
              children: [
                TextFormField(
                  readOnly: true,
                  enableInteractiveSelection: false,
                  focusNode: _disabledFocusNode,
                  initialValue: entry.value.location.cityName,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          final removed = _midPoints.removeAt(entry.key);
                          removed.dispose();
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
                SizedBox(height: 8.h),
                _buildTextField(
                  controller: entry.value.addressController,
                  label: tr('create_order.form.route.waypoint_address'),
                  icon: Icons.map_outlined,
                ),
              ],
            ),
          ),
        ),
        if (_midPoints.isNotEmpty) SizedBox(height: 4.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('create_order.route_points.title'),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    tr('create_order.route_points.optional'),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 160.w),
              child: TextButton.icon(
                onPressed: remaining > 0 ? _pickMidLocation : null,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(
                  remaining > 0
                      ? tr('create_order.route_points.add')
                      : tr('create_order.route_points.limit'),
                  style: TextStyle(fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  minimumSize: Size(0, 0),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  String _vehicleLabel(String value) {
    final key = 'vehicle_type.${value.toLowerCase()}';
    final translated = tr(key);
    if (translated != key) return translated;
    final match = vehicleTypeOptions.firstWhere(
      (option) => option.value == value,
      orElse: () => vehicleTypeOptions.first,
    );
    return match.label;
  }

  String _labelForOption(List<_DropdownOption<String>> options, String value) {
    final match = options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
    return match.label;
  }

  Future<void> _pickOption<T>({
    required String title,
    required List<_DropdownOption<T>> options,
    required T currentValue,
    required ValueChanged<T> onSelected,
  }) async {
    final sheetHeight = math.min(
      MediaQuery.of(context).size.height * 0.6,
      420.h,
    );
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SizedBox(
          height: sheetHeight,
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
                        itemCount: options.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey[200]),
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
                                color: isSelected
                                    ? Colors.black
                                    : Colors.black87,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[500],
                            ),
                            onTap: () =>
                                Navigator.of(context).pop(option.value),
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
      onSelected(picked);
    }
  }

  Widget _buildPhotoPicker() {
    final totalPhotos = _existingPhotoUrls.length + _selectedPhotos.length;
    final remainingSlots = _maxPhotos - totalPhotos;
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: [
        for (final url in _existingPhotoUrls) _RemotePhotoPreview(url: url),
        for (final entry in _selectedPhotos.asMap().entries)
          _PhotoPreview(
            photo: entry.value,
            onRemove: () => _removePhoto(entry.key),
          ),
        if (remainingSlots > 0) _AddPhotoTile(onTap: _pickPhotos),
      ],
    );
  }

  Widget _buildContactVisibilityTile() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('create_order.form.cargo.contact_visibility_title'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  tr('create_order.form.cargo.contact_visibility_subtitle'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _showPhoneToDrivers,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) => setState(() => _showPhoneToDrivers = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);

    String fallbackText(String value) =>
        value.trim().isEmpty ? '—' : value.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('create_order.form.summary.title'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.alt_route,
            title: tr('create_order.form.summary.route'),
            value:
                '${fallbackText(_departurePointController.text)} → ${fallbackText(_destinationPointController.text)}',
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.local_shipping,
            title: tr('create_order.form.summary.transport'),
            value: _vehicleOptions
                .firstWhere((option) => option.value == _selectedVehicleType)
                .label,
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.inventory_2,
            title: tr('create_order.form.summary.cargo'),
            value: fallbackText(_cargoNameController.text),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.payment,
            title: tr('create_order.form.summary.payment'),
            value:
                '${fallbackText(_amountController.text)} ${_currencyOptions.firstWhere((option) => option.value == _selectedCurrency).label} • ${_paymentTypeOptions.firstWhere((option) => option.value == _selectedPaymentType).label}',
          ),
          if (_notesController.text.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildSummaryRow(
              icon: Icons.note,
              title: tr('create_order.form.summary.note'),
              value: _notesController.text.trim(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32.w,
          width: 32.w,
          decoration: BoxDecoration(
            color: const Color(0xFF00B2FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: const Color(0xFF00B2FF)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapLocationHint(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey[700]),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedTransportationDate ?? now;
    final selected = await showAppDatePicker(
      context,
      title: tr('create_order.form.payment.transport_date'),
      initialDate: initial,
      firstDate: initial.isBefore(now) ? initial : now,
    );
    if (selected == null) return;
    setState(() {
      _selectedTransportationDate = selected;
      _transportDateController.text = _formatDateForField(selected);
    });
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;

      final normalizedFiles = <_PickedPhoto>[];
      for (final file in result.files) {
        final xfile = file.path != null
            ? XFile(file.path!, name: file.name)
            : XFile.fromData(file.bytes ?? Uint8List(0), name: file.name);
        final normalized = await _normalizePickedImage(
          xfile,
          fallbackBytes: file.bytes,
        );
        normalizedFiles.add(normalized);
      }

      setState(() {
        _selectedPhotos.addAll(normalizedFiles);
        if (_selectedPhotos.length > _maxPhotos) {
          _selectedPhotos.removeRange(_maxPhotos, _selectedPhotos.length);
        }
      });
    } catch (_) {
      _showError(tr('create_order.errors_extra.pick_photos'));
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _selectedPhotos.length) return;
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<_PickedPhoto> _normalizePickedImage(
    XFile file, {
    Uint8List? fallbackBytes,
  }) async {
    try {
      final sourceBytes = fallbackBytes ?? await file.readAsBytes();
      if (sourceBytes.isEmpty) {
        return _PickedPhoto(file: file, bytes: sourceBytes);
      }

      final decoded = image_lib.decodeImage(sourceBytes);
      if (decoded == null) {
        return _PickedPhoto(file: file, bytes: sourceBytes);
      }

      final encoded = image_lib.encodeJpg(decoded, quality: 85);
      final bytes = Uint8List.fromList(encoded);
      final normalized = XFile.fromData(
        bytes,
        name: file.name.isNotEmpty ? file.name : 'photo.jpg',
        mimeType: 'image/jpeg',
        length: bytes.length,
      );
      return _PickedPhoto(file: normalized, bytes: bytes);
    } catch (_) {
      final safeBytes = fallbackBytes ?? await _readSafeBytes(file);
      return _PickedPhoto(file: file, bytes: safeBytes);
    }
  }

  Future<Uint8List> _readSafeBytes(XFile file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<void> _submitForm() async {
    final departure = _departureLocation;
    final destination = _destinationLocation;
    final weight = double.tryParse(_weightController.text.trim());
    final amount = double.tryParse(_amountController.text.trim());
    final transportTerm = _transportDurationController.text.trim().isEmpty
        ? null
        : int.tryParse(_transportDurationController.text.trim());

    if (departure == null) {
      _showError(tr('create_order.errors.pick_departure'));
      return;
    }
    if (destination == null) {
      _showError(tr('create_order.errors.pick_destination'));
      return;
    }
    if (weight == null || weight <= 0) {
      _showError(tr('create_order.errors.weight'));
      return;
    }
    if (amount == null || amount <= 0) {
      _showError(tr('create_order.errors.amount'));
      return;
    }
    if (_cargoNameController.text.trim().isEmpty) {
      _showError(tr('create_order.errors.cargo_name'));
      return;
    }
    if (_requiresDepartureAddress &&
        _departureAddressController.text.trim().isEmpty) {
      _showError(tr('create_order.require_departure_address'));
      return;
    }
    if (_requiresDestinationAddress &&
        _destinationAddressController.text.trim().isEmpty) {
      _showError(tr('create_order.require_destination_address'));
      return;
    }
    if (transportTerm != null && (transportTerm < 1 || transportTerm > 7)) {
      _showError(tr('create_order.errors.transport_term'));
      return;
    }

    final waypoints = _midPoints.isEmpty
        ? <OrderWaypointRequest>[]
        : <OrderWaypointRequest>[
            OrderWaypointRequest(
              locationId: departure.id,
              sequence: 1,
              addressDetail: _departureAddressController.text.trim().isEmpty
                  ? null
                  : _departureAddressController.text.trim(),
            ),
            ..._midPoints.asMap().entries.map((entry) {
              final idx = entry.key;
              final wp = entry.value;
              return OrderWaypointRequest(
                locationId: wp.location.id,
                sequence: idx + 2,
                addressDetail: wp.addressController.text.trim().isEmpty
                    ? null
                    : wp.addressController.text.trim(),
              );
            }),
            OrderWaypointRequest(
              locationId: destination.id,
              sequence: _midPoints.length + 2,
              addressDetail: _destinationAddressController.text.trim().isEmpty
                  ? null
                  : _destinationAddressController.text.trim(),
            ),
          ];

    final request = CreateOrderRequest(
      departurePointId: departure.id,
      destinationPointId: destination.id,
      cargoName: _cargoNameController.text.trim(),
      vehicleType: _selectedVehicleType,
      loadingType: _selectedLoadingType,
      weightTons: weight,
      volumeCubicMeters: _parseDouble(_volumeController.text),
      lengthMeters: _parseDouble(_lengthController.text),
      widthMeters: _parseDouble(_widthController.text),
      heightMeters: _parseDouble(_heightController.text),
      description: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      transportationDate: _selectedTransportationDate,
      transportationTermDays: transportTerm,
      amount: amount,
      paymentType: _selectedPaymentType,
      currency: _selectedCurrency,
      photos: _selectedPhotos.map((photo) => photo.file).toList(),
      showPhoneToDrivers: _showPhoneToDrivers,
      departureAddressDetail: _departureAddressController.text.trim().isEmpty
          ? null
          : _departureAddressController.text.trim(),
      destinationAddressDetail:
          _destinationAddressController.text.trim().isEmpty
          ? null
          : _destinationAddressController.text.trim(),
      waypoints: waypoints,
    );

    final controller = ref.read(createOrderControllerProvider.notifier);
    final success = _isEditing
        ? await controller.updateOrder(
            widget.editingOrder!.id,
            request,
            includePhotos: _selectedPhotos.isNotEmpty,
          )
        : await controller.submit(request);
    if (!mounted) return;

    if (success) {
      ref.refresh(myOrdersProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? tr('create_order.success.updated')
                : tr('create_order.success.created'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = createOrderError(ref.read(createOrderControllerProvider));
      if (error != null) {
        _showError(error);
      }
    }
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  int? _parseInt(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _departurePointController.dispose();
    _departureAddressController.dispose();
    _destinationPointController.dispose();
    _destinationAddressController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _transportDateController.dispose();
    _transportDurationController.dispose();
    _cargoNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _disabledFocusNode.dispose();
    super.dispose();
  }
}

class _DropdownOption<T> {
  const _DropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _WaypointStop {
  _WaypointStop({required this.location, String? initialAddress}) {
    addressController = TextEditingController(text: initialAddress);
  }

  final LocationModel location;
  late final TextEditingController addressController;

  void dispose() {
    addressController.dispose();
  }
}

class _PickedPhoto {
  _PickedPhoto({required this.file, required this.bytes});

  final XFile file;
  final Uint8List bytes;
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.onRemove});

  final _PickedPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 96.w,
            height: 96.w,
            color: Colors.grey[200],
            child: photo.bytes.isEmpty
                ? const Icon(Icons.image_not_supported_outlined)
                : Image.memory(photo.bytes, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _RemotePhotoPreview extends StatelessWidget {
  const _RemotePhotoPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 96.w,
        height: 96.w,
        color: Colors.grey[200],
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96.w,
        height: 96.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF00B2FF), width: 1.2),
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: Color(0xFF00B2FF),
            ),
            SizedBox(height: 6.h),
            Text(
              tr('create_order.form.add_photo'),
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF00B2FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
