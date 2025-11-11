import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/data/repositories/location_repository.dart';

final locationSearchProvider =
    FutureProvider.autoDispose.family<List<LocationModel>, String>((ref, query) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.searchLocations(query: query);
});
