import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:fura24.kz/features/driver/domain/models/create_driver_announcement_request.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';
import 'package:fura24.kz/features/driver/providers/create_driver_announcement_provider.dart';
import 'package:fura24.kz/features/driver/providers/driver_announcements_provider.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:fura24.kz/features/transport/data/vehicle_type_options.dart';
import 'package:fura24.kz/shared/styles/app_input_decorations.dart';

const _pageBackground = Color(0xFFFFFFFF);
const _borderColor = Color(0xFFE3E8F0);
const _primaryColor = Color(0xFF00B2FF);
const _hintTextColor = Color(0xFF6F738B);

class DriverCreateAnnouncementPage extends ConsumerStatefulWidget {
  const DriverCreateAnnouncementPage({super.key, this.initialAnnouncement});

  final DriverAnnouncement? initialAnnouncement;

  @override
  ConsumerState<DriverCreateAnnouncementPage> createState() =>
      _DriverCreateAnnouncementPageState();
}

class _DriverCreateAnnouncementPageState
    extends ConsumerState<DriverCreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  final List<GlobalKey<FormState>> _formKeys = List.generate(
    3,
    (_) => GlobalKey<FormState>(),
  );
  int _currentStep = 0;
  late List<String> _stepTitles;
  late List<String> _stepDescriptions;

  LocationModel? _departure;
  LocationModel? _destination;
  bool _showRouteError = false;
  bool _isActive = true;
  String? _editingId;
  final List<_WaypointStop> _midPoints = [];
  final FocusNode _disabledFocusNode =
      FocusNode(skipTraversal: true, canRequestFocus: false);
  Locale? _lastLocale;

  static final List<_DriverFieldOption> _vehicleTypeOptions =
      vehicleTypeOptions
          .map(
            (option) => _DriverFieldOption(
              value: option.value,
              label: option.label,
            ),
          )
          .toList(growable: false);

  String _selectedVehicleType = _vehicleTypeOptions.first.value;
  String _selectedLoadingType = 'ANY';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAnnouncement;
    if (initial != null) {
      _editingId = initial.id;
      _departure = initial.departurePoint;
      _destination = initial.destinationPoint;
      if (initial.waypoints.length >= 2) {
        _departure = initial.waypoints.first.location;
        _destination = initial.waypoints.last.location;
        if (initial.waypoints.length > 2) {
          _midPoints.addAll(
            initial.waypoints.sublist(1, initial.waypoints.length - 1).map(
              (wp) => _WaypointStop(location: wp.location),
            ),
          );
        }
      }
      _selectedVehicleType = initial.vehicleType;
      _selectedLoadingType = initial.loadingType;
      _weightController.text = initial.weight.toStringAsFixed(1);
      if (initial.volume != null) {
        _volumeController.text = initial.volume!.toStringAsFixed(1);
      }
      _commentController.text = initial.comment;
      _isActive = initial.isActive;
      _selectedLoadingType = initial.loadingType;
      _selectedVehicleType = initial.vehicleType;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _volumeController.dispose();
    _commentController.dispose();
    _disabledFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_lastLocale != locale) {
      if (_lastLocale == null) {
        _updateLocalizedText(locale);
      } else {
        setState(() {
          _updateLocalizedText(locale);
        });
      }
    }
  }

  void _updateLocalizedText(Locale locale) {
    _stepTitles = [
      tr('driver_transport.create.step_titles.route'),
      tr('driver_transport.create.step_titles.vehicle'),
      tr('driver_transport.create.step_titles.params'),
    ];
    _stepDescriptions = [
      tr('driver_transport.create.step_desc.route'),
      tr('driver_transport.create.step_desc.vehicle'),
      tr('driver_transport.create.step_desc.params'),
    ];
    _lastLocale = locale;
  }

  List<_DriverFieldOption> get _loadingTypeOptions => const [
        'ANY',
        'BACK',
        'TOP',
        'SIDE',
        'BACK_SIDE_TOP',
      ]
          .map(
            (value) => _DriverFieldOption(
              value: value,
              label: tr(
                'driver_transport.create.loading.${value.toLowerCase()}',
              ),
            ),
          )
          .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createDriverAnnouncementControllerProvider);
    final isSubmitting = createState.isLoading;
    final routeError =
        _showRouteError && (_departure == null || _destination == null);
    final errorMessage = createDriverAnnouncementError(createState);
    final formKey = _formKeys[_currentStep];

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
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(right: 16.w, left: 16.w),
            child: SizedBox(height: 8.h, child: _ProgressBar(progress: (_currentStep + 1) / _stepTitles.length)),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 140.h),
                    children: [
                      if (_currentStep == 0) ...[
                        Text(
                          _editingId != null
                              ? tr('driver_transport.create.title_edit')
                              : tr('driver_transport.create.title_new'),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _editingId != null
                              ? tr('driver_transport.create.subtitle_edit')
                              : tr('driver_transport.create.subtitle_new'),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black.withOpacity(0.65),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 14.h),
                      ],
                      Text(
                        tr(
                          'driver_transport.create.step_of',
                          args: [
                            '${_currentStep + 1}',
                            '${_stepTitles.length}',
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _stepTitles[_currentStep],
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        _stepDescriptions[_currentStep],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black.withOpacity(0.65),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      ..._buildStepContent(routeError),
                      if (errorMessage != null) ...[
                        SizedBox(height: 16.h),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _NavigationBar(
          isFirstStep: _currentStep == 0,
          isLastStep: _currentStep == _stepTitles.length - 1,
          isSubmitting: isSubmitting,
          isEditing: _editingId != null,
          onBack: _goBack,
          onNext: _goNext,
          onSubmit: _submit,
        ),
      ),
    );
  }

  List<Widget> _buildStepContent(bool routeError) {
    switch (_currentStep) {
      case 0:
        return [
          _LocationField(
            label: tr('driver_transport.create.from'),
            value: _departure?.cityName,
            onTap: () => _pickLocation(isDeparture: true),
          ),
          SizedBox(height: 12.h),
            _WaypointList(
              midPoints: _midPoints,
              onAdd: _pickMidLocation,
              onRemove: (index) {
                setState(() => _midPoints.removeAt(index));
            },
            disabledFocusNode: _disabledFocusNode,
          ),
          SizedBox(height: 8.h),
          _LocationField(
            label: tr('driver_transport.create.to'),
            value: _destination?.cityName,
            onTap: () => _pickLocation(isDeparture: false),
          ),
          if (routeError) ...[
            SizedBox(height: 10.h),
            Text(
              tr('driver_transport.create.route_error'),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red[400],
              ),
            ),
          ],
        ];
      case 1:
        return [
          _SelectionField(
            label: tr('driver_transport.create.vehicle_type'),
            value: _labelFor(_vehicleTypeLocalizedOptions, _selectedVehicleType),
            hint: tr('driver_transport.create.select_type'),
            icon: Icons.local_shipping_outlined,
            onTap: _selectVehicleType,
          ),
          SizedBox(height: 12.h),
          _SelectionField(
            label: tr('driver_transport.create.loading_type'),
            value: _labelFor(_loadingTypeOptions, _selectedLoadingType),
            hint: tr('driver_transport.create.select_type'),
            icon: Icons.inventory_2_outlined,
            onTap: _selectLoadingType,
          ),
        ];
      default:
        return [
          _NumberField(
            controller: _weightController,
            decoration: _numberDecoration(
              label: tr('driver_transport.create.weight'),
              hint: tr('driver_transport.create.weight'),
              icon: Icons.fitness_center_outlined,
              isRequired: true,
            ),
            isRequired: true,
          ),
          SizedBox(height: 12.h),
          _NumberField(
            controller: _volumeController,
            decoration: _numberDecoration(
              label: tr('driver_transport.create.volume'),
              hint: tr('driver_transport.create.volume'),
              icon: Icons.width_normal_rounded,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _commentController,
            maxLines: 4,
            decoration: _commentDecoration(),
            inputFormatters: [
              LengthLimitingTextInputFormatter(400),
            ],
          ),
        ];
    }
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
                        ? tr('driver_transport.create.departure_point')
                        : tr('driver_transport.create.destination_point'),
                excludeLocationId:
                    isDeparture ? _destination?.id : _departure?.id,
              ),
            ),
          ),
    );

    if (selected == null) return;

    setState(() {
      if (isDeparture) {
        _departure = selected.location;
      } else {
        _destination = selected.location;
      }
      if (_departure != null && _destination != null) {
        _showRouteError = false;
      }
    });
  }

  Future<void> _pickMidLocation() async {
    if (_midPoints.length >= 3) return;
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
                title: tr('driver_transport.create.waypoint_title'),
                excludeLocationId: null,
              ),
            ),
          ),
    );
    if (selected == null) return;
    setState(() {
      _midPoints.add(_WaypointStop(location: selected.location));
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;
    final weight = _parseNumber(_weightController.text)!;
    final volume = _parseNumber(_volumeController.text);
    final waypoints =
        _midPoints.isEmpty
            ? <OrderWaypointRequest>[]
            : <OrderWaypointRequest>[
                OrderWaypointRequest(locationId: _departure!.id, sequence: 1),
                ..._midPoints.asMap().entries.map(
                  (entry) => OrderWaypointRequest(
                    locationId: entry.value.location.id,
                    sequence: entry.key + 2,
                  ),
                ),
                OrderWaypointRequest(
                  locationId: _destination!.id,
                  sequence: _midPoints.length + 2,
                ),
              ];
    final request = CreateDriverAnnouncementRequest(
      departurePointId: _departure!.id,
      destinationPointId: _destination!.id,
      vehicleType: _selectedVehicleType,
      loadingType: _selectedLoadingType,
      weight: weight,
      volume: volume,
      comment: _commentController.text,
      isActive: _isActive,
      waypoints: waypoints,
    );

    final notifier =
        ref.read(createDriverAnnouncementControllerProvider.notifier);
    final succeeded =
        _editingId != null
            ? await notifier.update(_editingId!, request)
            : await notifier.submit(request);
    if (!mounted) return;
    if (succeeded) {
      ref.invalidate(driverMyAnnouncementsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingId != null
                ? tr('driver_transport.create.success.updated')
                : tr('driver_transport.create.success.published'),
          ),
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      setState(() => _showRouteError = true);
      if (_departure == null || _destination == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('driver_transport.create.route_required'),
            ),
          ),
        );
        return false;
      }
    }
    final form = _formKeys[_currentStep].currentState;
    if (form != null && !form.validate()) {
      return false;
    }
    return true;
  }

  void _goNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  double? _parseNumber(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _labelFor(List<_DriverFieldOption> options, String value) {
    if (options.isEmpty) return '';
    final match =
        options.firstWhere(
          (option) => option.value == value,
          orElse: () => options.first,
        );
    return match.label;
  }

  List<_DriverFieldOption> get _vehicleTypeLocalizedOptions =>
      _vehicleTypeOptions
          .map(
            (option) => _DriverFieldOption(
              value: option.value,
              label: _vehicleLabel(option),
            ),
          )
          .toList(growable: false);

  String _vehicleLabel(_DriverFieldOption option) {
    final key =
        'driver_transport.create.vehicle_types.${option.value.toLowerCase()}';
    final localized = tr(key);
    if (localized == key) return option.label;
    return localized;
  }

  Future<void> _selectVehicleType() async {
    final selected = await _showOptionsSheet(
      title: tr('driver_transport.create.vehicle_type'),
      options: _vehicleTypeLocalizedOptions,
      currentValue: _selectedVehicleType,
    );
    if (selected != null) {
      setState(() => _selectedVehicleType = selected.value);
    }
  }

  Future<void> _selectLoadingType() async {
    final selected = await _showOptionsSheet(
      title: tr('driver_transport.create.loading_type'),
      options: _loadingTypeOptions,
      currentValue: _selectedLoadingType,
    );
    if (selected != null) {
      setState(() => _selectedLoadingType = selected.value);
    }
  }

  Future<_DriverFieldOption?> _showOptionsSheet({
    required String title,
    required List<_DriverFieldOption> options,
    required String currentValue,
  }) {
    return showModalBottomSheet<_DriverFieldOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == currentValue;
                      return ListTile(
                        onTap: () => Navigator.of(context).pop(option),
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.label),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? _primaryColor : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _numberDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool isRequired = false,
  }) {
    return InputDecoration(
      hintText: '${hint ?? label}${isRequired ? ' *' : ''}',
      hintStyle: TextStyle(fontSize: 14.sp, color: CupertinoColors.systemGrey),
      prefixIcon:
          icon != null
              ? Icon(icon, size: 20, color: Colors.grey[500])
              : null,
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
        borderSide: const BorderSide(color: _primaryColor, width: 1.4),
      ),
    );
  }

  InputDecoration _commentDecoration() {
    return InputDecoration(
      labelText: tr('driver_transport.create.comment'),
      hintText: tr('driver_transport.create.comment_hint'),
      alignLabelWithHint: true,
      prefixIcon: Icon(Icons.notes_outlined, size: 20, color: Colors.grey[500]),
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
        borderSide: const BorderSide(color: _primaryColor, width: 1.4),
      ),
    );
  }
}

class _WaypointList extends StatelessWidget {
  const _WaypointList({
    required this.midPoints,
    required this.onAdd,
    required this.onRemove,
    required this.disabledFocusNode,
  });

  final List<_WaypointStop> midPoints;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final FocusNode disabledFocusNode;

  @override
  Widget build(BuildContext context) {
    final remaining = 3 - midPoints.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (midPoints.isNotEmpty) SizedBox(height: 4.h),
        ...midPoints.asMap().entries.map(
          (entry) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: TextFormField(
              readOnly: true,
              enableInteractiveSelection: false,
              focusNode: disabledFocusNode,
              initialValue: entry.value.location.cityName,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => onRemove(entry.key),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: Color(0xFF00B2FF),
                    width: 1.2,
                  ),
                ),
              ),
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ),
        if (midPoints.isNotEmpty) SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('driver_transport.create.waypoints.title'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  tr('driver_transport.create.waypoints.subtitle'),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: remaining > 0 ? onAdd : null,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                remaining > 0
                    ? tr('driver_transport.create.waypoints.add')
                    : tr('driver_transport.create.waypoints.limit'),
                style: TextStyle(fontSize: 13.sp),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.onTap,
    this.value,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hasValue ? value : '$label *',
        hintStyle: TextStyle(fontSize: 14.sp, color: CupertinoColors.systemGrey),
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
          borderSide: const BorderSide(color: _primaryColor, width: 1.4),
        ),
      ),
      style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
    );
  }
}

class _WaypointStop {
  const _WaypointStop({required this.location});

  final LocationModel location;
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.icon,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hasValue ? value : (hint ?? ''),
        hintStyle: TextStyle(fontSize: 14.sp, color: CupertinoColors.systemGrey),
        prefixIcon:
            icon != null
                ? Icon(icon, size: 20, color: Colors.grey[500])
                : null,
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
          borderSide: const BorderSide(color: _primaryColor, width: 1.4),
        ),
      ),
      style: TextStyle(fontSize: 14.sp, color: Colors.black87, fontWeight: FontWeight.w600),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        ...children,
        SizedBox(height: 8.h),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.decoration,
    this.isRequired = false,
    this.validator,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final bool isRequired;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: decoration,
      validator:
          isRequired
              ? (value) {
                final parsed = _parse(value);
                if (parsed == null || parsed <= 0) {
                  return tr('driver_transport.create.validation.positive');
                }
                if (validator != null) return validator!(value);
                return null;
              }
              : (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = _parse(value);
                if (parsed == null) {
                  return tr('driver_transport.create.validation.number');
                }
                if (validator != null) return validator!(value);
                return null;
              },
    );
  }

  double? _parse(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}

class _DriverFieldOption {
  const _DriverFieldOption({required this.value, required this.label});
  final String value;
  final String label;
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isSubmitting,
    required this.isEditing,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final bool isSubmitting;
  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!, width: 1),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(tr('driver_transport.create.nav.back')),
                ),
              ),
            if (!isFirstStep) SizedBox(width: 12.w),
            Expanded(
                child: ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : () => (isLastStep ? onSubmit() : onNext()),
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
                child: isSubmitting
                    ? SizedBox(
                        height: 22.w,
                        width: 22.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        isLastStep
                            ? (
                                isEditing
                                    ? tr('driver_transport.create.nav.save')
                                    : tr('driver_transport.create.nav.publish')
                              )
                            : tr('driver_transport.create.nav.next'),
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
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress.clamp(0, 1),
        minHeight: 8.h,
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.titles, required this.currentStep});

  final List<String> titles;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            titles.length,
            (index) {
              final isActive = index == currentStep;
              final isDone = index < currentStep;
              return Expanded(
                child: Container(
                  height: 6.h,
                  margin: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4.w),
                  decoration: BoxDecoration(
                    color:
                        isDone
                            ? _primaryColor.withOpacity(0.7)
                            : isActive
                                ? _primaryColor
                                : Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: List.generate(
            titles.length,
            (index) {
              final isActive = index == currentStep;
              return Expanded(
                child: Text(
                  titles[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.black : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
