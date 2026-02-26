import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/business/data/models/partner_model.dart';
import 'package:logger/logger.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(ref.watch(dioProvider));
});

class PartnerRepository {
  PartnerRepository(this._dio);

  final Dio _dio;
  final _logger = Logger();

  Future<List<PartnerModel>> getPartners({String? city}) async {
    try {
      final response = await _dio.get(
        'partners/',
        queryParameters: city != null ? {'city': city} : null,
      );
      final items = _extractPartnerItems(response.data);
      return items.map(PartnerModel.fromJson).toList();
    } on DioException catch (e) {
      _logger.e('Failed to fetch partners', error: e);
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, st) {
      _logger.e('Failed to fetch partners', error: e, stackTrace: st);
      throw ApiException(tr('repository.partner.fetch_error'));
    }
  }

  List<Map<String, dynamic>> _extractPartnerItems(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      // Support common paginated shapes: {results: [...]}, {data: [...]}, etc.
      final keys = ['results', 'data', 'items', 'partners'];
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().toList();
        }
      }
      // Fallback: first list value in the map
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

  Future<void> createApplication({
    required String companyName,
    required String activity,
    required String companyDescription,
    required String countries,
    required String city,
    required String phone,
    required String email,
    required bool acceptedTerms,
    String? logoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'company_name': companyName,
        'activity': activity,
        'company_description': companyDescription,
        'countries': countries,
        'city': city,
        'phone': phone,
        'email': email,
        'accepted_terms': acceptedTerms,
        if (logoPath != null) 'logo': await MultipartFile.fromFile(logoPath),
      });

      await _dio.post(
        'partners/',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (e) {
      _logger.e('Failed to create partner application', error: e);
      throw ApiException(
        _extractErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, st) {
      _logger.e(
        'Failed to create partner application',
        error: e,
        stackTrace: st,
      );
      throw ApiException(tr('repository.partner.create_error'));
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
    return tr('repository.partner.network_error');
  }
}
