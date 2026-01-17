import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/payments/data/models/payment_model.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentsRepository(dio: dio);
});

class PaymentsRepository {
  PaymentsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<PaymentModel> createPayment(double amount) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'payments/create/',
        data: {'amount': amount},
      );

      final data = response.data;
      if (data == null) {
        throw ApiException(
          tr('repository.payments.empty_response'),
          statusCode: response.statusCode,
        );
      }

      return PaymentModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(tr('repository.payments.create_error'));
    }
  }

  String _extractErrorMessage(DioException exception) {
    final response = exception.response;
    if (response?.data is Map) {
      final data = response!.data as Map;
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return tr('repository.payments.network_error');
  }
}
