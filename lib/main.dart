import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/router/app_router.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  timeago.setLocaleMessages('ru', timeago.RuMessages());

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ru'), Locale('en'), Locale('kk')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      child: const ProviderScope(
        child: FuraApp(),
      ),
    ),
  );
}


class FuraApp extends ConsumerWidget {
  const FuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final theme = ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Основной фон
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8F9FA), // <- ИЗМЕНИЛ НА ЦВЕТ ФОНА
            elevation: 0,
            foregroundColor: Colors.black,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: 17.sp),
            bodyMedium: TextStyle(fontSize: 15.sp),
            bodySmall: TextStyle(fontSize: 14.sp),
          ),
          colorScheme: ColorScheme.light(
            background: const Color(0xFFF8F9FA), // Основной фон
            surface: Colors.white, // Для карточек и поверхностей
            primary: const Color(0xFF1E88E5),
            onSurface: Colors.black,
            onBackground: Colors.black,
            outline: const Color(0xFFEEEEEE),
          ),
          useMaterial3: false,
        );

        return MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          title: 'Fura24.kz',
          theme: theme,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: [
            ...context.localizationDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}