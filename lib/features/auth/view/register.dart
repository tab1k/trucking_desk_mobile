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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _acceptTerms = false;
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
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Подтвердите согласие с условиями')),
        );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          phoneNumber: _dialCode + _phoneController.text.trim(),
          password: _passwordController.text,
          passwordConfirm: _passwordConfirmController.text,
          email:
              _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
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
                'Создайте аккаунт',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Зарегистрируйтесь, чтобы начать пользоваться Fura24.',
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
                      hintText: 'Номер телефона *',
                      icon: Icons.phone_iphone_outlined,
                      prefix: _buildCountryPicker(),
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Обязательное поле';
                        }
                        if (trimmed.length > 20) {
                          return 'Макс. 20 символов';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _emailController,
                      hintText: 'Электронная почта (необязательно)',
                      icon: Icons.mail_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        final emailRegex = RegExp(
                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(trimmed)) {
                          return 'Некорректный email';
                        }
                        if (trimmed.length > 254) {
                          return 'Макс. 254 символа';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    Divider(color: Colors.grey.shade300, thickness: 1),
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _passwordController,
                      hintText: 'Пароль *',
                      icon: Icons.lock_outlined,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                        if (value.length < 6) {
                          return 'Минимум 6 символов';
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
                    SizedBox(height: 10.h),
                    AuthInputField(
                      controller: _passwordConfirmController,
                      hintText: 'Повторите пароль *',
                      icon: Icons.lock_outlined,
                      enabled: !isLoading,
                      obscureText: _obscurePasswordConfirm,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Обязательное поле';
                        }
                        if (value != _passwordController.text) {
                          return 'Пароли не совпадают';
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
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  setState(() {
                                    _obscurePasswordConfirm =
                                        !_obscurePasswordConfirm;
                                  });
                                },
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged:
                              isLoading
                                  ? null
                                  : (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                        ),
                        Expanded(
                          child: Text(
                            'Я принимаю условия использования и политику конфиденциальности',
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
                                  'Зарегистрироваться',
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
                            text: 'Уже есть аккаунт? ',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Войти',
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
