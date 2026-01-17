import 'package:fura24.kz/features/client/presentation/pages/dashboard_shell.dart';
import 'package:fura24.kz/features/profile/view/my_profile.dart';
import 'package:fura24.kz/features/profile/view/edit_profile_page.dart';
import 'package:fura24.kz/features/profile/view/wallet_page.dart';
import 'package:fura24.kz/features/profile/view/settings_page.dart';
import 'package:fura24.kz/features/splash_screen.dart';
import 'package:fura24.kz/features/welcome_screen.dart';
import 'package:fura24.kz/features/auth/view/login.dart';
import 'package:fura24.kz/features/auth/view/register.dart';
import 'package:fura24.kz/features/driver/view/driver_dashboard_shell.dart';
import 'package:fura24.kz/features/driver/view/driver_profile_page.dart';
import 'package:fura24.kz/features/driver/view/driver_verification_page.dart';
import 'package:fura24.kz/features/subscriptions/presentation/view/tariffs_page.dart';
import 'package:fura24.kz/features/driver/view/business/business_services_page.dart';
import 'package:fura24.kz/features/driver/view/business/become_partner_page.dart';
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
  GoRoute(
    path: DriverRoutes.verification,
    builder: (context, state) => const DriverVerificationPage(),
  ),
  GoRoute(
    path: DriverRoutes.tariffs,
    builder: (context, state) => const TariffsPage(),
  ),
  GoRoute(
    path: DriverRoutes.businessServices,
    builder: (context, state) => const BusinessServicesPage(),
  ),
  GoRoute(
    path: DriverRoutes.becomePartner,
    builder: (context, state) => const BecomePartnerPage(),
  ),

  // PROFILE
  GoRoute(
    path: ProfileRoutes.my_profile,
    builder: (context, state) => const MyProfilePage(),
  ),
  GoRoute(
    path: ProfileRoutes.edit_profile,
    builder: (context, state) => const EditProfilePage(),
  ),
  GoRoute(
    path: ProfileRoutes.wallet,
    builder: (context, state) => const WalletPage(),
  ),
  GoRoute(
    path: ProfileRoutes.settings,
    builder: (context, state) => const SettingsPage(),
  ),
];
