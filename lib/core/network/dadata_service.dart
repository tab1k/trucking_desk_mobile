import 'package:dio/dio.dart';

class DaDataService {
  static const String _apiKey = 'b02f26eb8228ee0ed312e5ea3e47ecf41d6bdcb8';
  static const String _endpoint =
      'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address';

  final Dio _dio = Dio();

  Future<List<String>> getSuggestions(String query, {String? city}) async {
    if (query.length < 2) return [];

    try {
      final fullQuery = city != null && city.isNotEmpty
          ? '$city, $query'
          : query;

      final response = await _dio.post(
        _endpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Token $_apiKey',
          },
        ),
        data: {
          'query': fullQuery,
          'count': 5,
          'locations': [
            {'country_iso_code': 'KZ'},
            {'country_iso_code': 'RU'},
            {'country_iso_code': 'BY'},
          ],
        },
      );

      if (response.statusCode == 200) {
        final suggestions = response.data['suggestions'] as List;
        return suggestions.map((s) {
          final value = s['value'] as String;
          final data = s['data'] as Map<String, dynamic>?;

          // If city is provided, return only street and house
          if (city != null && city.isNotEmpty && data != null) {
            final street = data['street'] as String?;
            final house = data['house'] as String?;

            if (street != null && street.isNotEmpty) {
              if (house != null && house.isNotEmpty) {
                return '$street, $house';
              }
              return street;
            }
          }

          // Otherwise return full address
          return value;
        }).toList();
      }
      return [];
    } catch (e) {
      // Fail silently for autocomplete
      return [];
    }
  }
}

final daDataService = DaDataService();
