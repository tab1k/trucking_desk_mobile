import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/driver/data/repositories/saved_routes_repository.dart';
import 'package:fura24.kz/features/driver/domain/models/saved_route.dart';

final savedRoutesProvider =
    AsyncNotifierProvider.family<
      SavedRoutesNotifier,
      List<SavedRoute>,
      String?
    >(() {
      return SavedRoutesNotifier();
    });

class SavedRoutesNotifier
    extends FamilyAsyncNotifier<List<SavedRoute>, String?> {
  @override
  Future<List<SavedRoute>> build(String? arg) async {
    final repository = ref.watch(savedRoutesRepositoryProvider);
    return repository.fetchSavedRoutes(type: arg);
  }

  Future<void> create({
    required String departureCityName,
    required String destinationCityName,
    String? type,
  }) async {
    final repository = ref.read(savedRoutesRepositoryProvider);
    await repository.createSavedRoute(
      departureCityName: departureCityName,
      destinationCityName: destinationCityName,
      type: type,
    );
    // Refresh to get the new ID and data from server
    // Invalidate the specific provider family member based on type
    ref.invalidate(savedRoutesProvider(type));
    // Also invalidate 'null' type if we want it to update general list?
    // But for now, just invalidate the specific one.
    // If type is null (all), this invalidates family(null).
  }

  Future<void> delete(int id) async {
    final previousState = state;
    // Optimistic update: immediately remove the item from local state
    state = state.whenData((routes) {
      return routes.where((route) => route.id != id).toList();
    });

    try {
      final repository = ref.read(savedRoutesRepositoryProvider);
      await repository.deleteSavedRoute(id);
    } catch (e) {
      // Revert if failed
      state = previousState;
      rethrow;
    }
  }
}
