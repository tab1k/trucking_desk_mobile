import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement.dart';
import 'package:fura24.kz/features/client/domain/models/driver_announcement_filters.dart';
import 'package:fura24.kz/features/driver/domain/models/create_driver_announcement_request.dart';

final driverAnnouncementRepositoryProvider =
    Provider<DriverAnnouncementRepository>((ref) {
      final dio = ref.watch(dioProvider);
      return DriverAnnouncementRepository(dio: dio);
    });

class DriverAnnouncementRepository {
  DriverAnnouncementRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<DriverAnnouncement>> fetchAnnouncements({
    DriverAnnouncementFilters? filters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'cargo/announcements/',
        queryParameters: filters?.toQueryParameters() ?? {},
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(
          'Пустой ответ от сервера',
          statusCode: response.statusCode,
        );
      }
      final items = _extractItems(data);
      return items.map((json) => DriverAnnouncement.fromJson(json)).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<List<DriverAnnouncement>> fetchFavoriteAnnouncements() async {
    try {
      final response = await _dio.get<dynamic>(
        'cargo/announcements/favorites/',
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(
          'Пустой ответ от сервера',
          statusCode: response.statusCode,
        );
      }
      final items = _extractItems(data);
      return items.map((json) => DriverAnnouncement.fromJson(json)).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<void> addFavorite(String announcementId) async {
    await _sendFavoriteRequest(
      () => _dio.post<dynamic>('cargo/announcements/$announcementId/favorite/'),
    );
  }

  Future<void> removeFavorite(String announcementId) async {
    await _sendFavoriteRequest(
      () =>
          _dio.delete<dynamic>('cargo/announcements/$announcementId/favorite/'),
    );
  }

  Future<DriverAnnouncement> createAnnouncement(
    CreateDriverAnnouncementRequest request,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        'cargo/announcements/',
        data: request.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DriverAnnouncement.fromJson(data);
      }
      throw ApiException(
        'Не удалось создать объявление',
        statusCode: response.statusCode,
      );
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<DriverAnnouncement> updateAnnouncement(
    String announcementId,
    CreateDriverAnnouncementRequest request,
  ) async {
    try {
      final response = await _dio.patch<dynamic>(
        'cargo/announcements/$announcementId/',
        data: request.toJson(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DriverAnnouncement.fromJson(data);
      }
      throw ApiException(
        'Не удалось сохранить объявление',
        statusCode: response.statusCode,
      );
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _dio.delete<dynamic>('cargo/announcements/$announcementId/');
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось удалить объявление');
    }
  }

  List<Map<String, dynamic>> _extractItems(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final keys = ['results', 'data', 'announcements', 'items'];
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().toList();
        }
      }
      for (final entry in data.entries) {
        if (entry.value is List) {
          return (entry.value as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    }
    return [];
  }

  String _extractErrorMessage(DioException exception) {
    final data = exception.response?.data;

    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) {
        return data['detail'] as String;
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.isNotEmpty) {
            return first;
          }
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    } else if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is String && first.isNotEmpty) {
        return first;
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }

    return 'Не удалось загрузить объявления';
  }

  Future<void> _sendFavoriteRequest(
    Future<Response<dynamic>> Function() requestFactory,
  ) async {
    try {
      await requestFactory();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }
}
