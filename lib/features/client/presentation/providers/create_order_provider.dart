import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';

final createOrderControllerProvider =
    StateNotifierProvider<CreateOrderController, AsyncValue<void>>((ref) {
      final repository = ref.watch(orderRepositoryProvider);
      return CreateOrderController(repository: repository);
    });

class CreateOrderController extends StateNotifier<AsyncValue<void>> {
  CreateOrderController({required OrderRepository repository})
    : _repository = repository,
      super(const AsyncData(null));

  final OrderRepository _repository;

  Future<bool> submit(CreateOrderRequest request) async {
    state = const AsyncLoading();
    try {
      await _repository.createOrder(request);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateOrder(
    String orderId,
    CreateOrderRequest request, {
    bool includePhotos = false,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateOrder(
        orderId,
        request,
        includePhotos: includePhotos,
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

String? createOrderError(AsyncValue<void> state) {
  return state.whenOrNull(
    error: (error, _) {
      if (error is ApiException) return error.message;
      return tr('create_order.default_error');
    },
  );
}
