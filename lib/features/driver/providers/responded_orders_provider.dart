import 'package:flutter_riverpod/flutter_riverpod.dart';

final respondedOrdersProvider = StateNotifierProvider<RespondedOrdersNotifier, Set<String>>(
  (ref) => RespondedOrdersNotifier(),
);

class RespondedOrdersNotifier extends StateNotifier<Set<String>> {
  RespondedOrdersNotifier() : super(<String>{});

  void markResponded(String orderId) {
    if (state.contains(orderId)) return;
    state = {...state, orderId};
  }

  bool hasResponded(String orderId) => state.contains(orderId);
}
