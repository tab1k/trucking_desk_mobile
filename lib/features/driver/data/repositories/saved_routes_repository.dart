import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/driver/domain/models/saved_route.dart';

final savedRoutesRepositoryProvider = Provider<SavedRoutesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SavedRoutesRepository(dio);
});

class SavedRoutesRepository {
  SavedRoutesRepository(this._dio);

  final Dio _dio;
  static const _basePath = 'cargo/saved_routes/';

  Future<List<SavedRoute>> fetchSavedRoutes({String? type}) async {
    final query = <String, dynamic>{};
    if (type != null) {
      query['type'] = type;
    }
    final response = await _dio.get<List<dynamic>>(
      _basePath,
      queryParameters: query,
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map((json) => SavedRoute.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<SavedRoute> createSavedRoute({
    required String departureCityName,
    required String destinationCityName,
    String? type,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _basePath,
      data: {
        'departure_city_input': departureCityName,
        'destination_city_input': destinationCityName,
        if (type != null) 'type': type,
      },
    );
    final data = response.data;
    if (data == null) throw Exception('Не удалось сохранить маршрут');
    return SavedRoute.fromJson(data);
  }

  Future<void> deleteSavedRoute(int id) async {
    await _dio.delete('$_basePath$id/');
  }
}
