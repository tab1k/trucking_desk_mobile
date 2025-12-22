import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';

class LocationPageResult {
  const LocationPageResult({
    required this.items,
    this.nextPageUrl,
  });

  final List<LocationModel> items;
  final String? nextPageUrl;
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LocationRepository(dio: dio);
});

class LocationRepository {
  LocationRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<LocationPageResult> searchLocationsPage({
    String query = '',
    String? nextPageUrl,
  }) async {
    try {
      Response<dynamic> response;
      if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
        response = await _dio.getUri<dynamic>(Uri.parse(nextPageUrl));
      } else {
        response = await _dio.get<dynamic>(
          'locations/',
          queryParameters: query.isEmpty ? null : {'search': query},
        );
      }

      final data = response.data;
      final items = _extractItems(data);
      final locations = items
          .whereType<Map<String, dynamic>>()
          .map(LocationModel.fromJson)
          .toList();
      final next = _extractNextPage(data);
      return LocationPageResult(items: locations, nextPageUrl: next);
    } on DioException catch (error) {
      final message = _extractErrorMessage(error);
      throw ApiException(message, statusCode: error.response?.statusCode);
    } catch (_) {
      throw ApiException('Не удалось загрузить список городов');
    }
  }

  Future<List<LocationModel>> searchLocations({String query = ''}) async {
    final page = await searchLocationsPage(query: query);
    return page.items;
  }

  List<dynamic> _extractItems(dynamic body) {
    if (body is List) {
      return List<dynamic>.from(body);
    }
    if (body is Map<String, dynamic>) {
      if (body['results'] is List) {
        return List<dynamic>.from(body['results'] as List);
      }
      if (body['data'] is List) {
        return List<dynamic>.from(body['data'] as List);
      }
      if (body.isNotEmpty && body.values.first is List) {
        return List<dynamic>.from(body.values.first as List);
      }
      return const [];
    }
    return const [];
  }

  String? _extractNextPage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final next = body['next'];
      if (next is String && next.isNotEmpty) return next;
    }
    return null;
  }

  String _extractErrorMessage(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return 'Сервер вернул ошибку при получении городов';
  }
}
