import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordConfirmPage extends ConsumerStatefulWidget {
  const ForgotPasswordConfirmPage({
    super.key,
    required this.uid,
    required this.token,
  });

  final String uid;
  final String token;

  @override
  ConsumerState<ForgotPasswordConfirmPage> createState() => _ForgotPasswordConfirmPageState();
}

class _ForgotPasswordConfirmPageState extends ConsumerState<ForgotPasswordConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.uid.isEmpty || widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет токена для сброса пароля')),
      );
      return;
    }

    final auth = ref.read(authControllerProvider.notifier);
    final success = await auth.confirmPasswordReset(
      uid: widget.uid,
      token: widget.token,
      newPassword: _passwordController.text,
      newPasswordConfirm: _passwordConfirmController.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль изменен. Теперь можно войти.')),
      );
      context.go(AuthRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый пароль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите новый пароль для вашего аккаунта.'),
            SizedBox(height: 16.h),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure1,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() => _obscure1 = !_obscure1);
                              },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Введите пароль';
                      if (value.length < 6) return 'Минимум 6 символов';
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: _passwordConfirmController,
                    obscureText: _obscure2,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Повторите пароль',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() => _obscure2 = !_obscure2);
                              },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Повторите пароль';
                      if (value != _passwordController.text) return 'Пароли не совпадают';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (authErrorMessage(authState) != null) ...[
              SizedBox(height: 12.h),
              Text(
                authErrorMessage(authState)!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
