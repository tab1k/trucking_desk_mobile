import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/features/auth/view/widgets/auth_dial_code_selector.dart';
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _dialCode = '+7';
  AuthRole _selectedRole = AuthRole.client;

  String get _roleCode => _selectedRole == AuthRole.client ? 'SENDER' : 'DRIVER';

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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(
          phoneNumber: _dialCode + _phoneController.text.trim(),
          password: _passwordController.text,
          role: _roleCode,
        );

    if (!mounted) return;
    if (success) {
      final session = await ref.read(authControllerProvider.notifier).readSession();
      final role = session?.user.role.toUpperCase() ?? _roleCode;
      final targetRoute = role == 'DRIVER' ? AppRoutes.driverHome : AppRoutes.home;
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
                      controller: _phoneController,
                      hintText: 'Номер телефона',
                      icon: Icons.phone_iphone_outlined,
                      prefix: _buildCountryPicker(),
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Введите номер телефона';
                        }
                        if (trimmed.length > 20) {
                          return 'Макс. 20 символов';
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
                        onPressed:
                            isLoading
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
                        onTap: () => context.go('/forgot-password'),
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
                        child:
                            isLoading
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
