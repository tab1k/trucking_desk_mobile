import 'package:flutter/material.dart';
import 'custom_page_route.dart';

class NavigationUtils {
  static void navigateWithBottomSheetAnimation(BuildContext context, Widget page) {
    Navigator.of(context).push(
      BottomSheetPageRoute(
        builder: (context) => page,
      ),
    );
  }

  // Дополнительные методы для других типов навигации
  static void navigateWithFadeAnimation(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}