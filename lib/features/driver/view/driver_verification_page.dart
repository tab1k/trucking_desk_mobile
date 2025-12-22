import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fura24.kz/features/client/data/repositories/profile_repository.dart';
import 'package:fura24.kz/features/driver/providers/driver_dashboard_tab_provider.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';

class DriverVerificationPage extends ConsumerStatefulWidget {
  const DriverVerificationPage({super.key});

  @override
  ConsumerState<DriverVerificationPage> createState() =>
      _DriverVerificationPageState();
}

class _DriverVerificationPageState
    extends ConsumerState<DriverVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _vehiclePassportNumberController = TextEditingController();
  final _idNumberController = TextEditingController();

  XFile? _licenseFront;
  XFile? _licenseBack;
  XFile? _vehiclePassportFront;
  XFile? _vehiclePassportBack;
  XFile? _idFront;
  XFile? _idBack;

  bool _isSubmitting = false;
  static const _backgroundColor = Color(0xFFF5F7FB);
  static const _borderColor = Color(0xFFE1E6F5);
  static const _primaryColor = Color(0xFF00B2FF);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _vehiclePassportNumberController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(ValueSetter<XFile?> setter) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setter(file);
      setState(() {});
    }
  }

  bool _filesReady() {
    return _licenseFront != null &&
        _licenseBack != null &&
        _vehiclePassportFront != null &&
        _vehiclePassportBack != null &&
        _idFront != null &&
        _idBack != null;
  }

  void _handleBack() {
    ref.read(driverDashboardTabIndexProvider.notifier).state = 3;
    context.go(AppRoutes.driverHome);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_filesReady()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Загрузите все обязательные файлы')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.submitDriverVerification(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        vehiclePassportNumber: _vehiclePassportNumberController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        licenseFront: _licenseFront!,
        licenseBack: _licenseBack!,
        vehiclePassportFront: _vehiclePassportFront!,
        vehiclePassportBack: _vehiclePassportBack!,
        idFront: _idFront!,
        idBack: _idBack!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Отправлено на проверку')));
      ref.read(driverDashboardTabIndexProvider.notifier).state = 3;
      context.go(AppRoutes.driverHome);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildFilePicker(
    String label,
    XFile? file,
    ValueSetter<XFile?> setter,
  ) {
    final hasFile = file != null;
    final Color statusColor =
        hasFile ? const Color(0xFF00B26B) : Colors.grey.shade600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: _isSubmitting ? null : () => _pickFile(setter),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: hasFile ? statusColor : _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                color: statusColor,
                size: 22,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      hasFile ? file!.name : 'JPEG/PNG, до 10 МБ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: (hasFile ? const Color(0xFF00B26B) : _primaryColor)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  hasFile ? 'Заменить' : 'Загрузить',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: hasFile ? const Color(0xFF00B26B) : _primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
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
              onPressed: _handleBack,
            ),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Text(
            'Верификация водителя',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            children: [
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: _borderColor),
                ),
                child: Text(
                  'Заполните данные и загрузите фото документов',
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ),
              _buildSection(
                title: 'Личные данные',
                children: [
                  _buildTextField(
                    _firstNameController,
                    'Имя',
                    icon: Icons.person_outline,
                  ),
                  _buildTextField(
                    _lastNameController,
                    'Фамилия',
                    icon: Icons.person_outline,
                  ),
                  _buildTextField(
                    _middleNameController,
                    'Отчество',
                    requiredField: false,
                    icon: Icons.person_outline,
                  ),
                ],
              ),
              _buildSection(
                title: 'Контакты',
                children: [
                  _buildTextField(
                    _emailController,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email_outlined,
                  ),
                  _buildTextField(
                    _phoneController,
                    'Телефон',
                    keyboardType: TextInputType.phone,
                    icon: Icons.call_outlined,
                  ),
                ],
              ),
              _buildSection(
                title: 'Данные документов',
                children: [
                  _buildTextField(
                    _licenseNumberController,
                    'Номер прав',
                    icon: Icons.badge_outlined,
                  ),
                  _buildTextField(
                    _vehiclePassportNumberController,
                    'Номер техпаспорта',
                    icon: Icons.directions_car_filled_outlined,
                  ),
                  _buildTextField(
                    _idNumberController,
                    'Номер удостоверения личности',
                    icon: Icons.credit_card,
                  ),
                ],
              ),
              _buildSection(
                title: 'Файлы документов',
                children: [
                  _buildFilePicker(
                    'Права (лицевая)',
                    _licenseFront,
                    (f) => _licenseFront = f,
                  ),
                  _buildFilePicker(
                    'Права (оборотная)',
                    _licenseBack,
                    (f) => _licenseBack = f,
                  ),
                  _buildFilePicker(
                    'Техпаспорт (лицевая)',
                    _vehiclePassportFront,
                    (f) => _vehiclePassportFront = f,
                  ),
                  _buildFilePicker(
                    'Техпаспорт (оборотная)',
                    _vehiclePassportBack,
                    (f) => _vehiclePassportBack = f,
                  ),
                  _buildFilePicker(
                    'Удостоверение личности (разворот)',
                    _idFront,
                    (f) => _idFront = f,
                  ),
                  _buildFilePicker(
                    'Удостоверение личности (оборотная)',
                    _idBack,
                    (f) => _idBack = f,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Отправить на проверку'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool requiredField = true,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredField && text.isEmpty) return 'Обязательное поле';
        if (label.toLowerCase().contains('email')) {
          final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
          if (!emailRegex.hasMatch(text)) return 'Некорректный email';
        }
        if (label.toLowerCase().contains('телефон')) {
          final cleaned = text.replaceAll(RegExp(r'[^0-9+]'), '');
          final phoneRegex = RegExp(r'^\+?[0-9]{6,20}$');
          if (!phoneRegex.hasMatch(cleaned)) return 'Некорректный телефон';
        }
        return null;
      },
      decoration: _fieldDecoration(
        label: label,
        isRequired: requiredField,
        icon: icon,
      ),
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          ..._withSpacing(children),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    return [
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i != children.length - 1) SizedBox(height: 12.h),
      ],
    ];
  }

  InputDecoration _fieldDecoration({
    required String label,
    required bool isRequired,
    IconData? icon,
  }) {
    final hint = '$label${isRequired ? ' *' : ''}';
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
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
        borderSide: const BorderSide(color: _primaryColor, width: 1.4),
      ),
    );
  }
}
