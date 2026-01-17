import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/client/domain/models/banner_model.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BannerRepository(dio: dio);
});

final activeBannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  final repository = ref.watch(bannerRepositoryProvider);
  return await repository.getActiveBanners();
});

class BannerRepository {
  final Dio _dio;

  BannerRepository({required Dio dio}) : _dio = dio;

  Future<List<BannerModel>> getActiveBanners() async {
    try {
      debugPrint('🔄 Loading banners from API...');

      final response = await _dio.get('/banners/');

      debugPrint('✅ API Response status: ${response.statusCode}');
      debugPrint('📦 API Response data type: ${response.data.runtimeType}');

      // Обрабатываем разные форматы ответа
      List<dynamic> data;

      if (response.data is List) {
        // Если ответ прямо список: [{...}, {...}]
        data = response.data;
        debugPrint('📋 Response is direct List with ${data.length} items');
      } else if (response.data is Map) {
        // Если ответ в формате JSON объекта
        if (response.data.containsKey('results')) {
          data = response.data['results'] ?? [];
          debugPrint('📋 Response has "results" key with ${data.length} items');
        } else if (response.data.containsKey('data')) {
          data = response.data['data'] ?? [];
          debugPrint('📋 Response has "data" key with ${data.length} items');
        } else {
          // Пробуем найти любой список в ответе
          data = [];
          response.data.forEach((key, value) {
            if (value is List) {
              data = value;
              debugPrint(
                '📋 Found List in key "$key" with ${data.length} items',
              );
            }
          });
        }
      } else {
        data = [];
        debugPrint('❓ Unknown response format');
      }

      if (data.isEmpty) {
        debugPrint('⚠️ No banners found, using mock data');
        return _getMockBanners();
      }

      debugPrint('🎯 Processing ${data.length} banner items...');

      final banners = <BannerModel>[];

      for (var i = 0; i < data.length; i++) {
        try {
          final item = data[i];
          debugPrint('📝 Item $i: $item');

          if (item is Map<String, dynamic>) {
            final banner = BannerModel.fromJson(item);
            banners.add(banner);
            debugPrint('✅ Successfully parsed banner: ${banner.title}');
          } else {
            debugPrint('❌ Item $i is not a Map, skipping');
          }
        } catch (e) {
          debugPrint('❌ Error parsing item $i: $e');
        }
      }

      debugPrint('🎨 Successfully loaded ${banners.length} banners');

      return banners;
    } on DioException catch (e) {
      debugPrint('❌ Dio Error: ${e.message}');
      debugPrint('📡 Error type: ${e.type}');
      debugPrint('🔗 URL: ${e.requestOptions.uri}');
      debugPrint('📊 Response status: ${e.response?.statusCode}');
      debugPrint('📄 Response data: ${e.response?.data}');

      // Используем мок данные при ошибке
      debugPrint('🔄 Using mock data due to error');
      return _getMockBanners();
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('🔄 Using mock data due to error');
      return _getMockBanners();
    }
  }

  List<BannerModel> _getMockBanners() {
    return [
      BannerModel(
        id: 1,
        title: 'Специальное предложение',
        imageUrl:
            'https://via.placeholder.com/300x150/6E41E2/FFFFFF?text=Banner+1',
        link: '/promo1',
      ),
      BannerModel(
        id: 2,
        title: 'Новые возможности',
        imageUrl:
            'https://via.placeholder.com/300x150/2196F3/FFFFFF?text=Banner+2',
        link: '/promo2',
      ),
      BannerModel(
        id: 3,
        title: 'Акция недели',
        imageUrl:
            'https://via.placeholder.com/300x150/00C968/FFFFFF?text=Banner+3',
        link: '/promo3',
      ),
    ];
  }
}
