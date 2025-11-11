import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';
import 'package:fura24.kz/features/client/presentation/providers/create_order_provider.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(4, (_) => GlobalKey<FormState>());
  final List<String> _stepTitles = const [
    'Маршрут',
    'Транспорт',
    'Сроки и оплата',
    'Груз и примечание',
  ];
  final List<String> _stepDescriptions = const [
    'Уточните точки погрузки и разгрузки.',
    'Расскажите о машине и параметрах перевозки.',
    'Выберите дату и условия оплаты.',
    'Проверьте детали и оставьте комментарий.',
  ];

  static const List<_DropdownOption<String>> _vehicleTypeOptions = [
    _DropdownOption(value: 'ANY', label: 'Любой транспорт'),
    _DropdownOption(value: 'TENT', label: 'Тент'),
    _DropdownOption(value: 'REFRIGERATOR', label: 'Рефрижератор'),
    _DropdownOption(value: 'FLATBED', label: 'Бортовой'),
    _DropdownOption(value: 'OPEN', label: 'Открытая платформа'),
    _DropdownOption(value: 'MANIPULATOR', label: 'Манипулятор'),
  ];

  static const List<_DropdownOption<String>> _loadingTypeOptions = [
    _DropdownOption(value: 'ANY', label: 'Любой тип погрузки'),
    _DropdownOption(value: 'BACK', label: 'Задняя'),
    _DropdownOption(value: 'TOP', label: 'Верхняя'),
    _DropdownOption(value: 'SIDE', label: 'Боковая'),
    _DropdownOption(value: 'BACK_SIDE_TOP', label: 'Зад + бок + верх'),
  ];

  static const List<_DropdownOption<String>> _paymentTypeOptions = [
    _DropdownOption(value: 'CASH', label: 'Наличными'),
    _DropdownOption(value: 'NON_CASH', label: 'Безналичный расчёт'),
    _DropdownOption(value: 'CARD', label: 'На карту'),
  ];

  static const List<_DropdownOption<String>> _currencyOptions = [
    _DropdownOption(value: 'KZT', label: 'Тенге (₸)'),
    _DropdownOption(value: 'USD', label: 'Доллар (\$)'),
    _DropdownOption(value: 'EUR', label: 'Евро (€)'),
    _DropdownOption(value: 'RUB', label: 'Рубли (₽)'),
    _DropdownOption(value: 'KGS', label: 'Сом (с)'),
  ];

  static const int _maxPhotos = 6;

  int _currentStep = 0;
  DateTime? _selectedTransportationDate;
  String _selectedVehicleType = _vehicleTypeOptions.first.value;
  String _selectedLoadingType = _loadingTypeOptions.first.value;
  String _selectedPaymentType = _paymentTypeOptions.first.value;
  String _selectedCurrency = _currencyOptions.first.value;
  LocationModel? _departureLocation;
  LocationModel? _destinationLocation;

  final _departurePointController = TextEditingController();
  final _destinationPointController = TextEditingController();
  final _cargoTypeController = TextEditingController();
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

  final List<File> _selectedPhotos = [];

  @override
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
            child: SizedBox(
              height: 8.h,
              child: _buildProgressStatus(),
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
                      if (_currentStep == 0) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Создание заказа',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Заполним данные по шагам — так проще ничего не пропустить.',
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
    final selected = await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: LocationPickerSheet(
          title: isDeparture ? 'Выбор пункта загрузки' : 'Выбор пункта разгрузки',
          excludeLocationId:
              isDeparture ? _destinationLocation?.id : _departureLocation?.id,
        ),
      ),
    );

    if (selected == null) return;

    setState(() {
      if (isDeparture) {
        _departureLocation = selected;
        _departurePointController.text = selected.cityName;
      } else {
        _destinationLocation = selected;
        _destinationPointController.text = selected.cityName;
      }
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
                    side: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('Назад'),
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
                      ? (isSubmitting ? 'Отправка…' : 'Отправить заявку')
                      : 'Продолжить',
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
    switch (step) {
      case 0:
        return _buildStepForm(
          step,
          children: [
            _buildLocationField(
              controller: _departurePointController,
              label: 'Пункт загрузки',
              onTap: () => _pickLocation(isDeparture: true),
            ),
            SizedBox(height: 12.h),
            _buildLocationField(
              controller: _destinationPointController,
              label: 'Пункт разгрузки',
              onTap: () => _pickLocation(isDeparture: false),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Выберите города из справочника — просто начните вводить название и выберите нужный вариант.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
              ),
            ),
          ],
        );
      case 1:
        return _buildStepForm(
          step,
          children: [
            _buildDropdownField<String>(
              label: 'Тип транспорта',
              value: _selectedVehicleType,
              options: _vehicleTypeOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedVehicleType = value);
              },
            ),
            SizedBox(height: 12.h),
            _buildDropdownField<String>(
              label: 'Тип погрузки',
              value: _selectedLoadingType,
              options: _loadingTypeOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedLoadingType = value);
              },
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _weightController,
              label: 'Вес (тонны)',
              icon: Icons.scale_outlined,
              isRequired: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _volumeController,
              label: 'Объём (м³)',
              icon: Icons.aspect_ratio_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _lengthController,
                    label: 'Длина (м)',
                    icon: Icons.straighten,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _widthController,
                    label: 'Ширина (м)',
                    icon: Icons.straighten,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    controller: _heightController,
                    label: 'Высота (м)',
                    icon: Icons.height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
              label: 'Дата перевозки',
              icon: Icons.calendar_today_outlined,
              onTap: () => _selectDate(context),
              readOnly: true,
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _transportDurationController,
              label: 'Срок перевозки, дней (1–7)',
              icon: Icons.access_time_outlined,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24.h),
            _buildDropdownField<String>(
              label: 'Вид оплаты',
              value: _selectedPaymentType,
              options: _paymentTypeOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedPaymentType = value);
              },
            ),
          ],
        );
      case 3:
        return _buildStepForm(
          step,
          children: [
            _buildSectionTitle('Детали груза'),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _cargoNameController,
              label: 'Название груза',
              icon: Icons.inventory_2_outlined,
              isRequired: true,
            ),
            SizedBox(height: 12.h),
            _buildTextField(
              controller: _cargoTypeController,
              label: 'ID типа груза (опционально)',
              icon: Icons.category_outlined,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _amountController,
                    label: 'Сумма',
                    icon: Icons.attach_money_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    isRequired: true,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 1,
                  child: _buildDropdownField<String>(
                    value: _selectedCurrency,
                    options: _currencyOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCurrency = value);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle('Фото груза'),
            SizedBox(height: 12.h),
            _buildPhotoPicker(),
            SizedBox(height: 8.h),
            Text(
              'Минимум 2 фото. Поддерживается JPG, PNG, HEIC.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle('Дополнительно'),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _notesController,
              label: 'Примечание',
              icon: Icons.note_outlined,
              maxLines: 3,
            ),
            SizedBox(height: 24.h),
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
            'Шаг ${step + 1} из ${_stepTitles.length}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _stepTitles[step],
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _stepDescriptions[step],
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
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
          return 'Выберите город';
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
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.black87,
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Обязательное поле';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdownField<T>({
    required List<_DropdownOption<T>> options,
    required ValueChanged<T?> onChanged,
    T? value,
    String? label,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option.value,
              child: Text(option.label, style: TextStyle(fontSize: 14.sp)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF00B2FF), width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
      style: TextStyle(
        fontSize: 14.sp,
        color: Colors.black87,
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
      isExpanded: true,
    );
  }

  Widget _buildPhotoPicker() {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: [
        for (final entry in _selectedPhotos.asMap().entries)
          _PhotoPreview(
            file: entry.value,
            onRemove: () => _removePhoto(entry.key),
          ),
        if (_selectedPhotos.length < _maxPhotos)
          _AddPhotoTile(onTap: _pickPhotos),
      ],
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
            'Краткий итог',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.alt_route,
            title: 'Маршрут',
            value:
                '${fallbackText(_departurePointController.text)} → ${fallbackText(_destinationPointController.text)}',
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.local_shipping,
            title: 'Транспорт',
            value: _vehicleTypeOptions
                .firstWhere((option) => option.value == _selectedVehicleType)
                .label,
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.inventory_2,
            title: 'Груз',
            value: fallbackText(_cargoNameController.text),
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            icon: Icons.payment,
            title: 'Оплата',
            value:
                '${fallbackText(_amountController.text)} ${_currencyOptions.firstWhere((option) => option.value == _selectedCurrency).label} • ${_paymentTypeOptions.firstWhere((option) => option.value == _selectedPaymentType).label}',
          ),
          if (_notesController.text.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildSummaryRow(
              icon: Icons.note,
              title: 'Примечание',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTransportationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00B2FF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _selectedTransportationDate = picked;
      _transportDateController.text =
          '${picked.day.toString().padLeft(2, '0')}.${picked.month.toString().padLeft(2, '0')}.${picked.year}';
      setState(() {});
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result == null) return;

      final files = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      if (files.isEmpty) return;

      setState(() {
        _selectedPhotos.addAll(files);
        if (_selectedPhotos.length > _maxPhotos) {
          _selectedPhotos.removeRange(_maxPhotos, _selectedPhotos.length);
        }
      });
    } catch (_) {
      _showError('Не удалось выбрать фотографии');
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _selectedPhotos.length) return;
    setState(() {
      _selectedPhotos.removeAt(index);
    });
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
      _showError('Выберите пункт загрузки.');
      return;
    }
    if (destination == null) {
      _showError('Выберите пункт разгрузки.');
      return;
    }
    if (weight == null || weight <= 0) {
      _showError('Введите вес груза в тоннах.');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Введите сумму заказа.');
      return;
    }
    if (_cargoNameController.text.trim().isEmpty) {
      _showError('Введите название груза.');
      return;
    }
    if (_selectedPhotos.length < 2) {
      _showError('Добавьте минимум 2 фото груза.');
      return;
    }
    if (transportTerm != null && (transportTerm < 1 || transportTerm > 7)) {
      _showError('Срок перевозки должен быть от 1 до 7 дней.');
      return;
    }

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
      description:
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      transportationDate: _selectedTransportationDate,
      transportationTermDays: transportTerm,
      amount: amount,
      paymentType: _selectedPaymentType,
      currency: _selectedCurrency,
      cargoTypeId: _parseInt(_cargoTypeController.text),
      photos: List<File>.from(_selectedPhotos),
    );

    final success =
        await ref.read(createOrderControllerProvider.notifier).submit(request);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заявка отправлена'),
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _departurePointController.dispose();
    _destinationPointController.dispose();
    _cargoTypeController.dispose();
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
    super.dispose();
  }
}

class _DropdownOption<T> {
  const _DropdownOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.file, required this.onRemove});

  final File file;
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
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
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
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
            const Icon(Icons.add_photo_alternate_outlined,
                color: Color(0xFF00B2FF)),
            SizedBox(height: 6.h),
            Text(
              'Добавить',
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
