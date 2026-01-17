import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fura24.kz/features/business/data/repositories/partner_repository.dart';
import 'package:fura24.kz/features/locations/presentation/widgets/location_picker_sheet.dart';
import 'package:dio/dio.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:fura24.kz/features/business/domain/models/partner_options.dart';

class BecomePartnerPage extends ConsumerStatefulWidget {
  const BecomePartnerPage({super.key});

  @override
  ConsumerState<BecomePartnerPage> createState() => _BecomePartnerPageState();
}

class _BecomePartnerPageState extends ConsumerState<BecomePartnerPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _activityController = TextEditingController();
  final _descController = TextEditingController();
  final _countriesController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _agreedToTerms = false;
  bool _isLoading = false;
  XFile? _selectedLogo;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  CountryCode _selectedCountry = CountryCode.fromCountryCode('KZ');

  @override
  void dispose() {
    _companyNameController.dispose();
    _activityController.dispose();
    _descController.dispose();
    _countriesController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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
              title: tr('driver_profile.partner_page.fields.city'),
            ),
          ),
        ),
      ),
    );

    if (selection != null) {
      if (!mounted) return;
      setState(() {
        _cityController.text = selection.location.cityName;
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      setState(() {
        _selectedLogo = image;
      });
    }
  }

  Future<void> _showSelectionSheet({
    required String title,
    required List<PartnerOption> options,
    required Function(PartnerOption) onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: 0.7.sh),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Text(
                title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final option = options[index];
                  return ListTile(
                    title: Text(
                      option.label,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    onTap: () {
                      onSelect(option);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('driver_profile.partner_page.terms_error'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final activityValue = PartnerOptions.activities
          .firstWhere(
            (e) => e.label == _activityController.text,
            orElse: () => PartnerOptions.activities.last,
          )
          .value;

      final countryValue = PartnerOptions.countries
          .firstWhere(
            (e) => e.label == _countriesController.text,
            orElse: () => PartnerOptions.countries.first,
          )
          .value;

      final fullPhone =
          '${_selectedCountry.dialCode}${_phoneFormatter.getUnmaskedText()}';

      await ref
          .read(partnerRepositoryProvider)
          .createApplication(
            companyName: _companyNameController.text,
            activity: activityValue,
            companyDescription: _descController.text,
            countries: countryValue,
            city: _cityController.text,
            phone: fullPhone,
            email: _emailController.text,
            acceptedTerms: _agreedToTerms,
            logoPath: _selectedLogo?.path,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('driver_profile.partner_page.success')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = tr('common.error');
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response?.data as Map;
          if (data.containsKey('detail')) {
            errorMessage = data['detail'].toString();
          } else {
            // Try to gather field errors
            final errors = <String>[];
            data.forEach((key, value) {
              if (value is List) {
                errors.add('$key: ${value.join(", ")}');
              } else {
                errors.add('$key: $value');
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join('\n');
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              tr('driver_profile.business_page.become_partner_header'),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('driver_profile.partner_page.header_subtitle'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64B5F6),
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    tr('driver_profile.partner_page.title'),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    tr('driver_profile.partner_page.subtitle'),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.company_name'),
                  ),
                  _buildTextField(
                    controller: _companyNameController,
                    hint: tr(
                      'driver_profile.partner_page.fields.company_name_hint',
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.activity'),
                  ),
                  _buildSelectableField(
                    controller: _activityController,
                    hint: tr('common.select'),
                    onTap: () => _showSelectionSheet(
                      title: tr('driver_profile.partner_page.fields.activity'),
                      options: PartnerOptions.activities,
                      onSelect: (opt) => _activityController.text = opt.label,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.logo'),
                  ),
                  _buildFilePicker(),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.description'),
                  ),
                  _buildTextField(
                    controller: _descController,
                    hint: tr(
                      'driver_profile.partner_page.fields.description_hint',
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.countries'),
                  ),
                  _buildSelectableField(
                    controller: _countriesController,
                    hint: tr('common.select'),
                    onTap: () => _showSelectionSheet(
                      title: tr('driver_profile.partner_page.fields.countries'),
                      options: PartnerOptions.countries,
                      onSelect: (opt) => _countriesController.text = opt.label,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.city'),
                  ),
                  _buildSelectableField(
                    controller: _cityController,
                    hint: tr('common.select'),
                    onTap: _pickCity,
                  ),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.phone'),
                  ),
                  _buildPhoneField(),
                  SizedBox(height: 16.h),

                  _buildInputLabel(
                    tr('driver_profile.partner_page.fields.email'),
                  ),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'example@mail.com',
                  ),
                  SizedBox(height: 20.h),

                  Row(
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: const Color(0xFF64B5F6),
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          tr('driver_profile.partner_page.fields.terms_agree'),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator.adaptive(
                              backgroundColor: Colors.white,
                            )
                          : Text(
                              tr('driver_profile.partner_page.submit'),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return tr('common.required_field');
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF4285F4)),
        ),
      ),
      style: TextStyle(fontSize: 15.sp, color: Colors.black),
    );
  }

  Widget _buildSelectableField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return tr('common.required_field');
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            suffixIcon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF4285F4)),
            ),
          ),
          style: TextStyle(fontSize: 15.sp, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CountryCodePicker(
            onChanged: (country) {
              setState(() {
                _selectedCountry = country;
              });
            },
            initialSelection: 'KZ',
            favorite: const ['KZ', 'RU', 'KG', 'UZ'],
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            padding: EdgeInsets.zero,
            flagWidth: 24.w,
            textStyle: TextStyle(fontSize: 15.sp, color: Colors.black),
          ),
          Container(width: 1, height: 24.h, color: Colors.grey[300]),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return tr('common.required_field');
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: '(777) 000-00-00',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 14.h,
                ),
              ),
              style: TextStyle(fontSize: 15.sp, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    return InkWell(
      onTap: _pickLogo,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedLogo != null
                    ? _selectedLogo!.name
                    : tr('driver_profile.partner_page.fields.logo_hint'),
                style: TextStyle(
                  color: _selectedLogo != null
                      ? Colors.black
                      : Colors.grey[700],
                  fontSize: 14.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
