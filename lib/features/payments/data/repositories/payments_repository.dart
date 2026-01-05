import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        throw Exception('No data received');
      }

      return PaymentModel.fromJson(data);
    } catch (e) {
      // Re-throw specific errors or handle them
      rethrow;
    }
  }
}
