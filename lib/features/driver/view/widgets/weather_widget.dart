import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:http/http.dart' as http;

// Defines a Riverpod provider to fetch and cache weather data
final weatherProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({double lat, double lng})>((
      ref,
      coords,
    ) async {
      // Use OpenMeteo for free weather data without API key
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${coords.lat}&longitude=${coords.lng}&current=temperature_2m,weather_code&wind_speed_unit=ms',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather');
      }
    });

class WeatherWidget extends ConsumerWidget {
  final double? latitude;
  final double? longitude;

  const WeatherWidget({super.key, this.latitude, this.longitude});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (latitude == null || longitude == null) {
      return const SizedBox.shrink();
    }

    final weatherAsyncValue = ref.watch(
      weatherProvider((lat: latitude!, lng: longitude!)),
    );

    return weatherAsyncValue.when(
      data: (data) => _buildWeatherCard(data['current']),
      loading: () => _buildLoadingCard(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> current) {
    final temp = current['temperature_2m'].round();
    final weatherCode = current['weather_code'];
    final iconData = _getIconForWeatherCode(weatherCode);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 24.w,
            color: Colors.amber, // Sun color by default, logic can be improved
          ),
          SizedBox(width: 8.w),
          Text(
            '$temp°C',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 80.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 16.w,
          height: 16.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  IconData _getIconForWeatherCode(int code) {
    // Basic mapping for WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs
    if (code == 0) return Icons.wb_sunny_rounded; // Clear sky
    if (code <= 3) return Icons.wb_cloudy_rounded; // Partly cloudy
    if (code <= 48) return Icons.foggy; // Fog
    if (code <= 67) return Icons.water_drop_rounded; // Rain
    if (code <= 77) return Icons.ac_unit_rounded; // Snow fall
    if (code <= 82) return Icons.tsunami; // Rain showers (approx)
    if (code <= 86) return Icons.ac_unit; // Snow showers
    if (code <= 99) return Icons.thunderstorm_rounded; // Thunderstorm
    return Icons.wb_sunny_rounded;
  }
}
