import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/auth/view/widgets/auth_dial_code_selector.dart';
import 'package:fura24.kz/features/auth/view/widgets/auth_input_field.dart';
import 'package:fura24.kz/features/auth/view/widgets/auth_role_toggle.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';

class SignUpPageView extends ConsumerStatefulWidget {
  const SignUpPageView({super.key});

  @override
  ConsumerState<SignUpPageView> createState() => _SignUpPageViewState();
}

class _SignUpPageViewState extends ConsumerState<SignUpPageView> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _referralController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _acceptTerms = false;
  String _dialCode = '+7';
  AuthRole _selectedRole = AuthRole.client;

  String get _roleCode =>
      _selectedRole == AuthRole.client ? 'SENDER' : 'DRIVER';
  int get _dialCodeDigitsLength =>
      _dialCode.replaceAll(RegExp(r'[^0-9]'), '').length;
  int get _maxLocalDigits => math.max(0, 20 - _dialCodeDigitsLength);

  String _extractDigits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  String _normalizePhoneDigits(String digits) {
    if (_dialCode == '+7') {
      var cleaned = digits;
      if (cleaned.length > 11) {
        cleaned = cleaned.substring(0, 11);
      }
      if (cleaned.length == 11 &&
          (cleaned.startsWith('7') || cleaned.startsWith('8'))) {
        cleaned = cleaned.substring(1);
      }
      if (cleaned.length > 10) {
        cleaned = cleaned.substring(0, 10);
      }
      return cleaned;
    }
    if (digits.isEmpty) return '';
    return digits.substring(0, math.min(digits.length, _maxLocalDigits));
  }

  String _formatPhone(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.write('(');
    final first = digits.substring(0, math.min(3, digits.length));
    buffer.write(first);
    if (digits.length <= 3) {
      return buffer.toString();
    }
    buffer.write(') ');
    final second = digits.substring(3, math.min(6, digits.length));
    buffer.write(second);
    if (digits.length <= 6) {
      return buffer.toString();
    }
    buffer.write('-');
    final third = digits.substring(6, math.min(8, digits.length));
    buffer.write(third);
    if (digits.length <= 8) {
      return buffer.toString();
    }
    buffer.write('-');
    final fourth = digits.substring(8, math.min(10, digits.length));
    buffer.write(fourth);
    if (digits.length <= 10) {
      return buffer.toString();
    }
    buffer.write(' ');
    buffer.write(digits.substring(10));
    return buffer.toString();
  }

  String _handlePhoneChanged(String value) {
    final digits = _normalizePhoneDigits(_extractDigits(value));
    return _formatPhone(digits);
  }

  Widget _buildCountryPicker() {
    return AuthDialCodeSelector(
      currentDialCode: _dialCode,
      onDialCodeChanged: (value) {
        if (_dialCode == value) return;
        setState(() {
          _dialCode = value;
        });
      },
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('auth.confirm_terms'.tr())));
      return;
    }

    final loginValue =
        _dialCode +
        _loginController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final emailValue = _emailController.text.trim();

    // 1. Request SMS Code
    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPhoneVerification(phoneNumber: loginValue);

    if (success && mounted) {
      // 2. Show Dialog
      _showVerificationDialog(phoneNumber: loginValue, email: emailValue);
    }
  }

  void _showVerificationDialog({required String phoneNumber, String? email}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VerificationSheet(
        phoneNumber: phoneNumber,
        onVerify: (pin) async {
          // 3. Confirm & Register
          final success = await ref
              .read(authControllerProvider.notifier)
              .confirmPhoneVerification(
                phoneNumber: phoneNumber,
                pin: pin,
                password: _passwordController.text,
                passwordConfirm: _passwordConfirmController.text,
                email: email,
                role: _roleCode,
                referralCode: _referralController.text.trim(),
              );

          if (success && mounted) {
            Navigator.pop(context); // Close sheet
            final session = await ref
                .read(authControllerProvider.notifier)
                .readSession();
            final role = session?.user.role.toUpperCase() ?? _roleCode;
            final targetRoute = role == 'DRIVER'
                ? AppRoutes.driverHome
                : AppRoutes.home;
            if (mounted) context.go(targetRoute);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: null,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Material(
            color: Colors.grey[200],
            shape: CircleBorder(),
            child: IconButton(
              icon: Icon(Icons.arrow_back, size: 20),
              color: Colors.black87,
              padding: EdgeInsets.zero,
              onPressed: () => context.go(AuthRoutes.welcomeScreen),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'auth.create_account'.tr(),
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'auth.register_to_start'.tr(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              AuthRoleToggle(
                value: _selectedRole,
                onChanged: (role) {
                  setState(() {
                    _selectedRole = role;
                  });
                },
              ),
              if (authErrorMessage(authState) != null) ...[
                SizedBox(height: 20.h),
                _AuthErrorBanner(message: authErrorMessage(authState)!),
              ],
              SizedBox(height: 20.h),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthInputField(
                      controller: _loginController,
                      hintText: 'auth.phone_number_required'.tr(),
                      icon: Icons.phone_iphone_outlined,
                      prefix: _buildCountryPicker(),
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      onChanged: _handlePhoneChanged,
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        if (raw.isEmpty) {
                          return 'auth.required_field'.tr();
                        }
                        final digitsOnly = raw.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (digitsOnly.isEmpty) {
                          return 'auth.enter_correct_number'.tr();
                        }
                        final combined = _dialCode + digitsOnly;
                        final phoneRegex = RegExp(r'^\+?[0-9]{6,20}$');
                        if (!phoneRegex.hasMatch(combined)) {
                          return 'auth.enter_correct_number'.tr();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _emailController,
                      hintText: 'auth.email_required'.tr(),
                      icon: Icons.mail_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'auth.required_field'.tr();
                        }
                        final emailRegex = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        );
                        if (!emailRegex.hasMatch(trimmed)) {
                          return 'auth.incorrect_email'.tr();
                        }
                        if (trimmed.length > 254) {
                          return 'auth.max_254_chars'.tr();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _passwordController,
                      hintText: 'auth.password_required'.tr(),
                      icon: Icons.lock_outlined,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.required_field'.tr();
                        }
                        if (value.length < 6) {
                          return 'auth.min_6_chars'.tr();
                        }
                        return null;
                      },
                      trailing: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500,
                          size: 20.w,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _passwordConfirmController,
                      hintText: 'auth.repeat_password_required'.tr(),
                      icon: Icons.lock_outlined,
                      enabled: !isLoading,
                      obscureText: _obscurePasswordConfirm,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.required_field'.tr();
                        }
                        if (value != _passwordController.text) {
                          return 'auth.passwords_do_not_match'.tr();
                        }
                        return null;
                      },
                      trailing: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _obscurePasswordConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey.shade500,
                          size: 20.w,
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePasswordConfirm =
                                      !_obscurePasswordConfirm;
                                });
                              },
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _referralController,
                      hintText: 'auth.referral_code_optional'.tr(),
                      enabled: !isLoading,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        if (trimmed.length > 10) {
                          return 'auth.max_10_chars'.tr();
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _acceptTerms = value ?? false;
                                  });
                                },
                        ),
                        Expanded(
                          child: Text(
                            'auth.accept_terms'.tr(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black.withOpacity(0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'auth.register_btn'.tr(),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    Center(
                      child: GestureDetector(
                        onTap: () => context.go(AuthRoutes.login),
                        child: RichText(
                          text: TextSpan(
                            text: 'auth.already_have_account'.tr(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              TextSpan(
                                text: 'auth.login_text'.tr(),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFBDBD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB00020)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB00020),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationSheet extends StatefulWidget {
  const _VerificationSheet({required this.phoneNumber, required this.onVerify});

  final String phoneNumber;
  final Function(String) onVerify;

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  final _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'auth.verify_phone_title'.tr(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'auth.sms_sent_to'.tr(args: [widget.phoneNumber]),
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 24.h),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            autofocus: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '0000',
              hintStyle: TextStyle(color: Colors.grey[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length == 4) {
                widget.onVerify(_pinController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'auth.confirm_btn'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
