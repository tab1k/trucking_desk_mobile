import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/auth/view/widgets/auth_input_field.dart';
import 'package:fura24.kz/features/auth/view/widgets/auth_role_toggle.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';

class SignInPageView extends ConsumerStatefulWidget {
  const SignInPageView({super.key});

  @override
  ConsumerState<SignInPageView> createState() => _SignInPageViewState();
}

class _SignInPageViewState extends ConsumerState<SignInPageView> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  AuthRole _selectedRole = AuthRole.client;
  bool _isPhoneMode = false;

  String get _roleCode =>
      _selectedRole == AuthRole.client ? 'SENDER' : 'DRIVER';

  String _handleLoginChanged(String value) {
    final digits = _extractDigits(value);
    // Fix: Don't switch to phone mode if there are letters (e.g. email like 'tabik85...')
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(value);
    final isPhone = digits.isNotEmpty && !value.contains('@') && !hasLetters;

    if (_isPhoneMode != isPhone) {
      setState(() {
        _isPhoneMode = isPhone;
      });
    }

    if (!isPhone) return value;
    final normalized = _normalizePhoneDigits(digits);
    return _formatPhone(normalized);
  }

  String _extractDigits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  String _normalizePhoneDigits(String digits) {
    if (digits.isEmpty) return '';
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
    return buffer.toString();
  }

  String _normalizePhoneValue(String value) {
    final digits = _normalizePhoneDigits(_extractDigits(value));
    if (digits.isEmpty) return value.trim();
    return '+7$digits';
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(
          login: _isPhoneMode
              ? _normalizePhoneValue(_loginController.text)
              : _loginController.text.trim(),
          password: _passwordController.text,
          role: _roleCode,
        );

    if (!mounted) return;
    if (success) {
      final session = await ref
          .read(authControllerProvider.notifier)
          .readSession();
      final role = session?.user.role.toUpperCase() ?? _roleCode;
      final targetRoute = role == 'DRIVER'
          ? AppRoutes.driverHome
          : AppRoutes.home;
      if (!mounted) return;
      context.go(targetRoute);
    }
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
              SizedBox(height: 20.h),
              Text(
                'Добро пожаловать\nобратно!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Введите свои данные, чтобы продолжить работу в Fura24.',
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
                      hintText: 'Телефон или email',
                      icon: _isPhoneMode
                          ? null
                          : Icons.alternate_email_outlined,
                      prefix: _isPhoneMode
                          ? Text(
                              '+7',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            )
                          : null,
                      keyboardType: _isPhoneMode
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      enabled: !isLoading,
                      onChanged: _handleLoginChanged,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Введите телефон или email';
                        }
                        if (_isPhoneMode) {
                          final digits = _normalizePhoneDigits(
                            _extractDigits(trimmed),
                          );
                          if (digits.length < 10) {
                            return 'Введите корректный телефон';
                          }
                          return null;
                        }
                        final emailRegex = RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        );
                        final phoneRegex = RegExp(r'^\+?[0-9]{6,20}$');
                        if (!(emailRegex.hasMatch(trimmed) ||
                            phoneRegex.hasMatch(trimmed))) {
                          return 'Введите корректный телефон или email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _passwordController,
                      hintText: 'Пароль',
                      icon: Icons.lock_outlined,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
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
                    SizedBox(height: 16.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://fura24.kz/auth/password-reset/'),
                        ),
                        child: Text(
                          'Забыли пароль?',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
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
                                'Войти',
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
                        onTap: () => context.go(AuthRoutes.register),
                        child: RichText(
                          text: TextSpan(
                            text: 'Ещё нет аккаунта? ',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Зарегистрироваться',
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
