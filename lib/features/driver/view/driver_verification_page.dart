import 'package:easy_localization/easy_localization.dart';
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
        SnackBar(content: Text('driver_verification.errors.upload_all'.tr())),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('driver_verification.success'.tr())),
      );
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
    final Color statusColor = hasFile
        ? const Color(0xFF00B26B)
        : Colors.grey.shade600;
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
                      'driver_verification.files.placeholder'.tr(),
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
                  hasFile
                      ? 'driver_verification.files.replace'.tr()
                      : 'driver_verification.files.upload'.tr(),
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
            'driver_verification.title'.tr(),
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
                  'driver_verification.subtitle'.tr(),
                  style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                ),
              ),
              _buildSection(
                title: 'driver_verification.personal_data'.tr(),
                children: [
                  _buildTextField(
                    _firstNameController,
                    'driver_verification.fields.first_name'.tr(),
                    icon: Icons.person_outline,
                  ),
                  _buildTextField(
                    _lastNameController,
                    'driver_verification.fields.last_name'.tr(),
                    icon: Icons.person_outline,
                  ),
                  _buildTextField(
                    _middleNameController,
                    'driver_verification.fields.middle_name'.tr(),
                    requiredField: false,
                    icon: Icons.person_outline,
                  ),
                ],
              ),
              _buildSection(
                title: 'driver_verification.contacts'.tr(),
                children: [
                  _buildTextField(
                    _emailController,
                    'driver_verification.fields.email'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.email_outlined,
                  ),
                  _buildTextField(
                    _phoneController,
                    'driver_verification.fields.phone'.tr(),
                    keyboardType: TextInputType.phone,
                    icon: Icons.call_outlined,
                  ),
                ],
              ),
              _buildSection(
                title: 'driver_verification.docs_data'.tr(),
                children: [
                  _buildTextField(
                    _licenseNumberController,
                    'driver_verification.fields.license_number'.tr(),
                    icon: Icons.badge_outlined,
                  ),
                  _buildTextField(
                    _vehiclePassportNumberController,
                    'driver_verification.fields.vp_number'.tr(),
                    icon: Icons.directions_car_filled_outlined,
                  ),
                  _buildTextField(
                    _idNumberController,
                    'driver_verification.fields.id_number'.tr(),
                    icon: Icons.credit_card,
                  ),
                ],
              ),
              _buildSection(
                title: 'driver_verification.files_data'.tr(),
                children: [
                  _buildFilePicker(
                    'driver_verification.files.license_front'.tr(),
                    _licenseFront,
                    (f) => _licenseFront = f,
                  ),
                  _buildFilePicker(
                    'driver_verification.files.license_back'.tr(),
                    _licenseBack,
                    (f) => _licenseBack = f,
                  ),
                  _buildFilePicker(
                    'driver_verification.files.vp_front'.tr(),
                    _vehiclePassportFront,
                    (f) => _vehiclePassportFront = f,
                  ),
                  _buildFilePicker(
                    'driver_verification.files.vp_back'.tr(),
                    _vehiclePassportBack,
                    (f) => _vehiclePassportBack = f,
                  ),
                  _buildFilePicker(
                    'driver_verification.files.id_front'.tr(),
                    _idFront,
                    (f) => _idFront = f,
                  ),
                  _buildFilePicker(
                    'driver_verification.files.id_back'.tr(),
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
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('driver_verification.submit_btn'.tr()),
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
        if (requiredField && text.isEmpty)
          return 'driver_verification.errors.required'.tr();
        if (label.toLowerCase().contains('email')) {
          final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
          if (!emailRegex.hasMatch(text))
            return 'driver_verification.errors.invalid_email'.tr();
        }
        if (label.toLowerCase().contains('телефон')) {
          final cleaned = text.replaceAll(RegExp(r'[^0-9+]'), '');
          final phoneRegex = RegExp(r'^\+?[0-9]{6,20}$');
          if (!phoneRegex.hasMatch(cleaned))
            return 'driver_verification.errors.invalid_phone'.tr();
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
      prefixIcon: icon != null
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
}
