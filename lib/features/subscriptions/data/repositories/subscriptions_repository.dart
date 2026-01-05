import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/subscriptions/data/models/tariff_model.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SubscriptionsRepository(dio: dio);
});

class SubscriptionsRepository {
  SubscriptionsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<TariffModel>> fetchTariffs() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('subscriptions/');
      final data = response.data;
      if (data == null) return [];
      
      final list = data['tariffs'] as List?;
      if (list == null) return [];

      return list.map((e) => TariffModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // Return empty list or rethrow as specific exception
      // For now, let's return generic error or empty
      rethrow; 
    }
  }

  Future<void> purchaseTariff(String code) async {
    try {
      await _dio.post('subscriptions/purchase/', data: {'tariff_code': code});
    } catch (e) {
      rethrow;
    }
  }
}
