import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/subscriptions/data/models/tariff_model.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((
  ref,
) {
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

      return list
          .map((e) => TariffModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      // Return empty list on parsing errors
      return [];
    }
  }

  Future<void> purchaseTariff(String code) async {
    try {
      await _dio.post('subscriptions/purchase/', data: {'tariff_code': code});
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(tr('repository.subscriptions.purchase_error'));
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
    return tr('repository.subscriptions.network_error');
  }
}
