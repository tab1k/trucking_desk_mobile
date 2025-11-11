import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Отслеживает текущую вкладку в кабинете водителя.
final driverDashboardTabIndexProvider = StateProvider<int>((ref) => 0);
