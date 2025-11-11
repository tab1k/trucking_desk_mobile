import 'package:fura24.kz/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'route_pages.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: AuthRoutes.splash_screen,
  routes: appRoutes,
);