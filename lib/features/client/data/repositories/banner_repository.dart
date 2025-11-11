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
      print('🔄 Loading banners from API...');
      
      final response = await _dio.get('/banners/');
      
      print('✅ API Response status: ${response.statusCode}');
      print('📦 API Response data type: ${response.data.runtimeType}');
      
      // Обрабатываем разные форматы ответа
      List<dynamic> data;
      
      if (response.data is List) {
        // Если ответ прямо список: [{...}, {...}]
        data = response.data;
        print('📋 Response is direct List with ${data.length} items');
      } else if (response.data is Map) {
        // Если ответ в формате JSON объекта
        if (response.data.containsKey('results')) {
          data = response.data['results'] ?? [];
          print('📋 Response has "results" key with ${data.length} items');
        } else if (response.data.containsKey('data')) {
          data = response.data['data'] ?? [];
          print('📋 Response has "data" key with ${data.length} items');
        } else {
          // Пробуем найти любой список в ответе
          data = [];
          response.data.forEach((key, value) {
            if (value is List) {
              data = value;
              print('📋 Found List in key "$key" with ${data.length} items');
            }
          });
        }
      } else {
        data = [];
        print('❓ Unknown response format');
      }
      
      if (data.isEmpty) {
        print('⚠️ No banners found, using mock data');
        return _getMockBanners();
      }
      
      print('🎯 Processing ${data.length} banner items...');
      
      final banners = <BannerModel>[];
      
      for (var i = 0; i < data.length; i++) {
        try {
          final item = data[i];
          print('📝 Item $i: $item');
          
          if (item is Map<String, dynamic>) {
            final banner = BannerModel.fromJson(item);
            banners.add(banner);
            print('✅ Successfully parsed banner: ${banner.title}');
          } else {
            print('❌ Item $i is not a Map, skipping');
          }
        } catch (e) {
          print('❌ Error parsing item $i: $e');
        }
      }
      
      print('🎨 Successfully loaded ${banners.length} banners');
      
      return banners;
      
    } on DioException catch (e) {
      print('❌ Dio Error: ${e.message}');
      print('📡 Error type: ${e.type}');
      print('🔗 URL: ${e.requestOptions.uri}');
      print('📊 Response status: ${e.response?.statusCode}');
      print('📄 Response data: ${e.response?.data}');
      
      // Используем мок данные при ошибке
      print('🔄 Using mock data due to error');
      return _getMockBanners();
    } catch (e) {
      print('❌ Unexpected error: $e');
      print('🔄 Using mock data due to error');
      return _getMockBanners();
    }
  }

  List<BannerModel> _getMockBanners() {
    return [
      BannerModel(
        id: 1,
        title: 'Специальное предложение',
        imageUrl: 'https://via.placeholder.com/300x150/6E41E2/FFFFFF?text=Banner+1',
        link: '/promo1',
      ),
      BannerModel(
        id: 2,
        title: 'Новые возможности',
        imageUrl: 'https://via.placeholder.com/300x150/2196F3/FFFFFF?text=Banner+2',
        link: '/promo2',
      ),
      BannerModel(
        id: 3,
        title: 'Акция недели',
        imageUrl: 'https://via.placeholder.com/300x150/00C968/FFFFFF?text=Banner+3',
        link: '/promo3',
      ),
    ];
  }
}
