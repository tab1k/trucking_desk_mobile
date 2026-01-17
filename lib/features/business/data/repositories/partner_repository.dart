import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final list = response.data as List;
      return list.map((e) => PartnerModel.fromJson(e)).toList();
    } catch (e, st) {
      _logger.e('Failed to fetch partners', error: e, stackTrace: st);
      rethrow;
    }
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

      await _dio.post('partners/', data: formData);
    } catch (e, st) {
      _logger.e(
        'Failed to create partner application',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
