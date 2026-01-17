import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/reviews/domain/models/review.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewRepository(dio: dio);
});

class ReviewRepository {
  const ReviewRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Submit a review for an order
  /// Only sender can review the driver
  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post(
        'reviews/create/',
        data: {'order_id': orderId, 'rating': rating, 'comment': comment ?? ''},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException('Не удалось отправить отзыв');
    }
  }

  Future<List<Review>> getMyReviews() async {
    try {
      final response = await _dio.get('reviews/my/');
      final data = response.data;
      if (data is List) {
        return data.map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = _extractErrorMessage(e);
      throw ApiException(message, statusCode: statusCode);
    } catch (_) {
      throw ApiException('Не удалось загрузить отзывы');
    }
  }

  String _extractErrorMessage(DioException exception) {
    final responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      if (responseData['error'] is String) {
        return responseData['error'] as String;
      }
      if (responseData['detail'] is String) {
        return responseData['detail'] as String;
      }
      if (responseData.values.isNotEmpty) {
        final firstValue = responseData.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          final value = firstValue.first;
          if (value is String) return value;
        } else if (firstValue is String) {
          return firstValue;
        }
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания ответа сервера';
      case DioExceptionType.badResponse:
        return 'Сервер вернул ошибку';
      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером';
      default:
        return 'Произошла неизвестная ошибка';
    }
  }
}
