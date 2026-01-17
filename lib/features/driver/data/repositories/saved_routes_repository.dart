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
    print('🔍 [SavedRoutes] Fetching saved routes, type: $type');
    try {
      final query = <String, dynamic>{};
      if (type != null) {
        query['type'] = type;
      }
      final response = await _dio.get<List<dynamic>>(
        _basePath,
        queryParameters: query,
      );
      print('✅ [SavedRoutes] Response received: ${response.statusCode}');
      final data = response.data;
      if (data == null) {
        print('⚠️ [SavedRoutes] Response data is null');
        return [];
      }
      final routes = data
          .map((json) => SavedRoute.fromJson(json as Map<String, dynamic>))
          .toList();
      print('✅ [SavedRoutes] Parsed ${routes.length} routes');
      return routes;
    } on DioException catch (e) {
      print('❌ [SavedRoutes] DioException: ${e.type}');
      print('   Status code: ${e.response?.statusCode}');
      print('   Response data: ${e.response?.data}');
      print('   Message: ${e.message}');

      // If server returns 500 error, return empty list instead of crashing
      if (e.response?.statusCode == 500) {
        print('⚠️ [SavedRoutes] Server error 500, returning empty list');
        return [];
      }
      rethrow;
    } catch (e, stack) {
      print('❌ [SavedRoutes] Error fetching routes: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<SavedRoute> createSavedRoute({
    required String departureCityName,
    required String destinationCityName,
    String? type,
  }) async {
    print(
      '🔍 [SavedRoutes] Creating route: $departureCityName -> $destinationCityName, type: $type',
    );
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _basePath,
        data: {
          'departure_city_input': departureCityName,
          'destination_city_input': destinationCityName,
          if (type != null) 'type': type,
        },
      );
      print('✅ [SavedRoutes] Route created: ${response.statusCode}');
      final data = response.data;
      if (data == null) throw Exception('Не удалось сохранить маршрут');
      return SavedRoute.fromJson(data);
    } on DioException catch (e) {
      print('❌ [SavedRoutes] DioException creating route: ${e.type}');
      print('   Status code: ${e.response?.statusCode}');
      print('   Response data: ${e.response?.data}');

      // If server returns 500, throw a user-friendly error
      if (e.response?.statusCode == 500) {
        throw Exception('Сервер временно недоступен. Попробуйте позже.');
      }
      rethrow;
    } catch (e, stack) {
      print('❌ [SavedRoutes] Error creating route: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> deleteSavedRoute(int id) async {
    print('🔍 [SavedRoutes] Deleting route: $id');
    try {
      await _dio.delete('$_basePath$id/');
      print('✅ [SavedRoutes] Route deleted: $id');
    } on DioException catch (e) {
      print('❌ [SavedRoutes] DioException deleting route: ${e.type}');
      print('   Status code: ${e.response?.statusCode}');

      // If server returns 500, throw a user-friendly error
      if (e.response?.statusCode == 500) {
        throw Exception('Сервер временно недоступен. Попробуйте позже.');
      }
      rethrow;
    } catch (e, stack) {
      print('❌ [SavedRoutes] Error deleting route: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
