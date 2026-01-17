import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:fura24.kz/features/auth/controller/auth_controller.dart';

class SimpleSplashScreen extends ConsumerStatefulWidget {
  const SimpleSplashScreen({super.key});

  @override
  ConsumerState<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends ConsumerState<SimpleSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Минимальная задержка для показа сплеш-скрина
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authController = ref.read(authControllerProvider.notifier);
    final session = await authController.readSession();

    if (session != null) {
      final role = session.user.role.toUpperCase();
      final targetRoute = role == 'DRIVER'
          ? AppRoutes.driverHome
          : AppRoutes.home;

      // Пытаемся обновить сессию
      final result = await authController.refreshSession(session: session);

      if (result == SessionRefreshResult.refreshed) {
        // Успешно обновили токен - переходим на главную
        if (mounted) context.go(targetRoute);
      } else {
        // Не удалось обновить (просрочен refresh token) - на welcome
        if (mounted) context.go(AuthRoutes.welcomeScreen);
      }
    } else {
      // Нет сохраненной сессии - на welcome screen
      if (mounted) context.go(AuthRoutes.welcomeScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'app_title'.tr(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'splash.subtitle'.tr(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
