import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';
import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:image_picker/image_picker.dart';

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
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (exception) {
      if (kDebugMode) {
        debugPrint('Cargo request POST failed: ${exception.response?.data}');
      }
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось создать заявку. Попробуйте позже.');
    }
  }

  Future<FormData> _buildFormData(
    CreateOrderRequest request, {
    bool includePhotos = true,
  }) async {
    // Отправляем waypoints только если есть промежуточные точки
    final hasWaypoints = request.waypoints.length > 2;

    final formData = FormData();

    void addField(String key, Object value) {
      formData.fields.add(MapEntry(key, value.toString()));
    }

    addField('cargo_name', request.cargoName);
    addField('vehicle_type', request.vehicleType);
    addField('loading_type', request.loadingType);
    addField('weight', _numToString(request.weightTons));
    addField('amount', _numToString(request.amount));
    addField('payment_type', request.paymentType);
    addField('currency', request.currency);
    addField('show_phone_to_drivers', request.showPhoneToDrivers);

    if (hasWaypoints) {
      final first = request.waypoints.first;
      final last = request.waypoints.last;
      addField('departure_point', first.locationId);
      addField('destination_point', last.locationId);

      final waypointPayload = request.waypoints
          .asMap()
          .entries
          .map(
            (entry) => {
              'location': entry.value.locationId,
              'sequence': entry.value.sequence ?? (entry.key + 1),
              'address_detail': entry.value.addressDetail,
            },
          )
          .toList();
      addField('waypoints', jsonEncode(waypointPayload));
    } else {
      addField('departure_point', request.departurePointId);
      addField('destination_point', request.destinationPointId);
    }

    void addNumber(String key, double? value) {
      if (value == null) return;
      addField(key, _numToString(value));
    }

    void addInt(String key, int? value) {
      if (value == null) return;
      addField(key, value);
    }

    void addString(String key, String? value) {
      if (value == null || value.isEmpty) return;
      addField(key, value);
    }

    addNumber('volume_cubic_meters', request.volumeCubicMeters);
    addNumber('length', request.lengthMeters);
    addNumber('width', request.widthMeters);
    addNumber('height', request.heightMeters);
    addNumber('distance_km', request.distanceKm);
    addNumber('estimated_time_hours', request.estimatedTimeHours);
    addNumber('total_cost', request.totalCost);
    addString('description', request.description);
    addString('departure_address_detail', request.departureAddressDetail);
    addString('destination_address_detail', request.destinationAddressDetail);

    if (request.transportationDate != null) {
      final date = request.transportationDate!;
      final formatted =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      addField('transportation_date', formatted);
    }

    addInt('transportation_term_days', request.transportationTermDays);

    final files = <MultipartFile>[];
    for (final file in request.photos) {
      files.add(await _multipartFromXFile(file));
    }
    if (includePhotos && files.isNotEmpty) {
      formData.files.addAll(
        files.map((file) => MapEntry<String, MultipartFile>('photos', file)),
      );
    }

    return formData;
  }

  Future<OrderDetail> fetchOrderDetail(String orderId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'cargo/requests/$orderId/',
      );
      final data = response.data;
      if (data == null) {
        throw ApiException(
          'Пустой ответ от сервера',
          statusCode: response.statusCode,
        );
      }
      return OrderDetail.fromJson(data);
    } on DioException catch (exception) {
      if (kDebugMode) {
        debugPrint('Cargo request PATCH failed: ${exception.response?.data}');
      }
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<void> updateOrder(
    String orderId,
    CreateOrderRequest request, {
    bool includePhotos = false,
  }) async {
    try {
      final formData = await _buildFormData(
        request,
        includePhotos: includePhotos,
      );
      await _dio.patch<Map<String, dynamic>>(
        'cargo/requests/$orderId/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось сохранить изменения. Попробуйте позже.');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _dio.delete<void>('cargo/requests/$orderId/');
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось удалить заказ. Попробуйте позже.');
    }
  }

  Future<List<OrderSummary>> fetchOrders() async {
    try {
      final response = await _dio.get<dynamic>('cargo/requests/');
      final data = response.data;

      if (data == null) {
        throw ApiException(
          'Пустой ответ от сервера',
          statusCode: response.statusCode,
        );
      }

      final items = _extractOrderItems(data);
      if (items.isEmpty) {
        return [];
      }

      return items.map((item) => OrderSummary.fromJson(item)).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<List<OrderSummary>> fetchAvailableOrders({
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        'cargo/requests/available/',
        queryParameters: filters,
      );
      final data = response.data;

      if (data == null) {
        throw ApiException(
          'Пустой ответ от сервера',
          statusCode: response.statusCode,
        );
      }

      final items = _extractOrderItems(data);
      if (items.isEmpty) {
        return [];
      }

      return items.map((item) => OrderSummary.fromJson(item)).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<List<OrderSummary>> fetchDriverFavoriteOrders() async {
    try {
      final response = await _dio.get<dynamic>('cargo/requests/favorites/');
      final data = response.data;

      if (data == null) {
        throw ApiException(
          'Пустой ответ от сервера',
          statusCode: response.statusCode,
        );
      }

      final items = _extractOrderItems(data);
      if (items.isEmpty) {
        return [];
      }

      return items.map((item) => OrderSummary.fromJson(item)).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<void> addDriverFavorite(String orderId) async {
    try {
      await _dio.post<void>('cargo/requests/$orderId/favorite/');
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<void> removeDriverFavorite(String orderId) async {
    try {
      await _dio.delete<void>('cargo/requests/$orderId/favorite/');
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    }
  }

  Future<OrderDetail> cancelOrder(String orderId, {String? reason}) {
    return _postOrderAction(orderId, 'cancel', data: _reasonPayload(reason));
  }

  Future<OrderDetail> releaseDriver(String orderId, {String? reason}) {
    return _postOrderAction(
      orderId,
      'release-driver',
      data: _reasonPayload(reason),
    );
  }

  Future<OrderDetail> markDriverReady(String orderId) {
    return _postOrderAction(orderId, 'mark-ready');
  }

  Future<OrderDetail> markDriverPickedUp(String orderId) {
    return _postOrderAction(orderId, 'mark-picked-up');
  }

  Future<OrderDetail> confirmPickup(String orderId) {
    return _postOrderAction(orderId, 'confirm-pickup');
  }

  Future<OrderDetail> markDriverDelivered(String orderId) {
    return _postOrderAction(orderId, 'mark-delivered');
  }

  Future<OrderDetail> confirmDelivery(String orderId) {
    return _postOrderAction(orderId, 'confirm-delivery');
  }

  Future<List<OrderLocationPoint>> fetchOrderLocations(
    String orderId, {
    int limit = 20,
  }) async {
    final safeLimit = limit.clamp(1, 50);
    try {
      final response = await _dio.get<dynamic>(
        'cargo/requests/$orderId/locations/',
        queryParameters: {'limit': safeLimit},
      );
      final data = response.data;
      final items =
          (data as List?)?.whereType<Map<String, dynamic>>() ?? const [];
      return items.map(OrderLocationPoint.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось загрузить координаты. Попробуйте позже.');
    }
  }

  Future<OrderLocationPoint> submitDriverLocation(
    String orderId, {
    required double latitude,
    required double longitude,
    String? note,
    DateTime? reportedAt,
  }) async {
    final payload = <String, dynamic>{
      'latitude': _formatCoordinate(latitude),
      'longitude': _formatCoordinate(longitude),
    };
    final trimmed = note?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      payload['note'] = trimmed;
    }
    if (reportedAt != null) {
      payload['reported_at'] = reportedAt.toIso8601String();
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'cargo/requests/$orderId/locations/',
        data: payload,
      );
      final data = response.data;
      if (data == null) {
        throw ApiException('Пустой ответ от сервера');
      }
      return OrderLocationPoint.fromJson(data);
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось отправить координаты');
    }
  }

  Future<void> createDriverBid({
    required String orderId,
    required double amount,
    String? comment,
  }) async {
    final payload = <String, dynamic>{
      'order': orderId,
      'amount': _numToString(amount),
    };
    final trimmed = comment?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      payload['comment'] = trimmed;
    }
    try {
      await _dio.post<Map<String, dynamic>>('cargo/bids/', data: payload);
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось отправить отклик. Попробуйте позже.');
    }
  }

  Future<OrderBidInfo> acceptBid(String bidId) async {
    return _postBidAction(bidId, 'accept');
  }

  Future<OrderBidInfo> rejectBid(String bidId) async {
    return _postBidAction(bidId, 'reject');
  }

  Future<OrderBidInfo> confirmDriverBid(String bidId) {
    return _postBidAction(bidId, 'driver-confirm');
  }

  Future<OrderBidInfo> declineDriverBid(String bidId) {
    return _postBidAction(bidId, 'driver-decline');
  }

  Future<List<OrderBidInfo>> fetchOrderBids({required String orderId}) async {
    try {
      final response = await _dio.get<dynamic>(
        'cargo/bids/',
        queryParameters: {'order': orderId},
      );
      final data = response.data;
      List<Map<String, dynamic>> items = const [];
      if (data is List) {
        items = data.whereType<Map<String, dynamic>>().toList();
      } else if (data is Map<String, dynamic>) {
        final results = data['results'];
        if (results is List) {
          items = results.whereType<Map<String, dynamic>>().toList();
        }
      }
      return items.map(OrderBidInfo.fromJson).toList();
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось загрузить отклики. Попробуйте позже.');
    }
  }

  List<Map<String, dynamic>> _extractOrderItems(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final keys = ['results', 'data', 'orders', 'items'];
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

  Future<OrderDetail> _postOrderAction(
    String orderId,
    String action, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'cargo/requests/$orderId/$action/',
        data: data,
      );
      final body = response.data;
      if (body == null) {
        throw ApiException('Пустой ответ от сервера');
      }
      return OrderDetail.fromJson(body);
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось обновить заказ. Попробуйте позже.');
    }
  }

  Future<OrderBidInfo> _postBidAction(String bidId, String action) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'cargo/bids/$bidId/$action/',
      );
      final data = response.data;
      if (data == null) {
        throw ApiException('Пустой ответ от сервера');
      }
      return OrderBidInfo.fromJson(data);
    } on DioException catch (exception) {
      throw ApiException(
        _extractErrorMessage(exception),
        statusCode: exception.response?.statusCode,
      );
    } catch (_) {
      throw ApiException('Не удалось обработать отклик. Попробуйте позже.');
    }
  }

  Map<String, dynamic>? _reasonPayload(String? reason) {
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    return {'reason': trimmed};
  }

  String _numToString(num value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  String _formatCoordinate(double value) {
    return value.toStringAsFixed(6);
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
        return 'Неизвестная ошибка при создании объявления.';
    }
  }

  Future<MultipartFile> _multipartFromXFile(XFile file) async {
    final filename = file.name.isNotEmpty ? file.name : 'photo.jpg';

    if (!kIsWeb && file.path.isNotEmpty) {
      return MultipartFile.fromFile(file.path, filename: filename);
    }

    final bytes = await file.readAsBytes();
    return MultipartFile.fromBytes(bytes, filename: filename);
  }
}
