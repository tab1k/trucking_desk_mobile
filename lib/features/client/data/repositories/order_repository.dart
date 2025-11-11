import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRepository(dio: dio);
});

class OrderRepository {
  OrderRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> createOrder(CreateOrderRequest request) async {
    if (request.photos.length < 2) {
      throw ApiException('Нужно приложить минимум 2 фото груза');
    }

    final formData = await _buildFormData(request);

    try {
      await _dio.post<Map<String, dynamic>>(
        'cargo/requests/',
        data: formData,
      );
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось создать заявку. Попробуйте позже.');
    }
  }

  Future<FormData> _buildFormData(CreateOrderRequest request) async {
    final map = <String, dynamic>{
      'departure_point': request.departurePointId,
      'destination_point': request.destinationPointId,
      'cargo_name': request.cargoName,
      'vehicle_type': request.vehicleType,
      'loading_type': request.loadingType,
      'weight': _numToString(request.weightTons),
      'amount': _numToString(request.amount),
      'payment_type': request.paymentType,
      'currency': request.currency,
    };

    void addNumber(String key, double? value) {
      if (value == null) return;
      map[key] = _numToString(value);
    }

    void addInt(String key, int? value) {
      if (value == null) return;
      map[key] = value;
    }

    void addString(String key, String? value) {
      if (value == null || value.isEmpty) return;
      map[key] = value;
    }

    addInt('cargo_type', request.cargoTypeId);
    addNumber('volume_cubic_meters', request.volumeCubicMeters);
    addNumber('length', request.lengthMeters);
    addNumber('width', request.widthMeters);
    addNumber('height', request.heightMeters);
    addNumber('distance_km', request.distanceKm);
    addNumber('estimated_time_hours', request.estimatedTimeHours);
    addNumber('total_cost', request.totalCost);
    addString('description', request.description);

    if (request.transportationDate != null) {
      final date = request.transportationDate!;
      final formatted = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      map['transportation_date'] = formatted;
    }

    addInt('transportation_term_days', request.transportationTermDays);

    final files = <MultipartFile>[];
    for (final file in request.photos) {
      final filename = file.path.split(Platform.pathSeparator).last;
      files.add(
        await MultipartFile.fromFile(
          file.path,
          filename: filename.isEmpty ? 'photo.jpg' : filename,
        ),
      );
    }
    map['photos'] = files;

    return FormData.fromMap(map);
  }

  String _numToString(num value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
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

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания ответа сервера';
      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером';
      case DioExceptionType.badResponse:
        return 'Сервер вернул ошибку';
      default:
        return 'Неизвестная ошибка при создании заявки';
    }
  }
}
