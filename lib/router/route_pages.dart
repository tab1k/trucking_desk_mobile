import 'package:fura24.kz/features/client/presentation/pages/dashboard_shell.dart';
import 'package:fura24.kz/features/profile/view/my_profile.dart';
import 'package:fura24.kz/features/splash_screen.dart';
import 'package:fura24.kz/features/welcome_screen.dart';
import 'package:fura24.kz/features/auth/view/login.dart';
import 'package:fura24.kz/features/auth/view/register.dart';
import 'package:fura24.kz/features/driver/view/driver_dashboard_shell.dart';
import 'package:fura24.kz/features/driver/view/driver_profile_page.dart';
import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';

final List<GoRoute> appRoutes = [
  GoRoute(
    path: AuthRoutes.splash_screen,
    builder: (context, state) => const SimpleSplashScreen(),
  ),
  GoRoute(
    path: AuthRoutes.welcomeScreen,
    builder: (context, state) => const WelcomeScreenWithImage(),
  ),
  GoRoute(
    path: AuthRoutes.login,
    builder: (context, state) => const SignInPageView(),
  ),
  GoRoute(
    path: AuthRoutes.register,
    builder: (context, state) => const SignUpPageView(),
  ),
  GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const MyHomePageView(title: 'Главная'),
  ),
  GoRoute(
    path: AppRoutes.driverHome,
    builder: (context, state) => const DriverDashboardShellPage(),
  ),

  GoRoute(
    path: DriverRoutes.profile,
    builder: (context, state) => const DriverProfilePage(),
  ),


  // PROFILE

  GoRoute(
    path: ProfileRoutes.my_profile,
    builder: (context, state) => const MyProfilePage(),
  )
];
