import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fura24.kz/core/network/dio_provider.dart';
import 'package:fura24.kz/features/notifications/domain/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationsRepository(dio: dio);
});

class NotificationsRepository {
  NotificationsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const _localKey = 'app_notifications';

  Future<List<AppNotification>> fetchNotifications() async {
    final local = await _readLocal();
    try {
      final response = await _dio.get<dynamic>('notifications/');
      final data = response.data;
      final remote = _parseList(data);
      final merged = _mergeAndSort(remote, local);
      await _saveLocal(merged);
      return merged;
    } catch (_) {
      return local;
    }
  }

  Future<void> markAsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await _dio.post<dynamic>(
        'notifications/mark-read/',
        data: {'ids': ids},
      );
    } catch (_) {
      // ignore network errors, fallback to local mark
    }
    await _markLocalAsRead(ids);
  }

  Future<void> addNotification(AppNotification notification) async {
    try {
      await _dio.post<dynamic>(
        'notifications/',
        data: notification.toJson(),
      );
    } catch (_) {
      // ignore network errors, still cache locally
    }
    final local = await _readLocal();
    final updated = _mergeAndSort([notification, ...local], const []);
    await _saveLocal(updated);
  }

  Future<void> removeByEntity(String entityId) async {
    if (entityId.isEmpty) return;
    final current = await _readLocal();
    final filtered =
        current.where((n) => (n.entityId ?? '') != entityId).toList();
    await _saveLocal(filtered);
  }

  List<AppNotification> _parseList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
    }
    if (data is Map<String, dynamic>) {
      final keys = ['results', 'data', 'items', 'notifications'];
      for (final key in keys) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
        }
      }
    }
    return const [];
  }

  Future<List<AppNotification>> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
      }
    } catch (_) {
      // ignore parse errors
    }
    return const [];
  }

  Future<void> _saveLocal(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString(_localKey, jsonEncode(jsonList));
  }

  Future<void> _markLocalAsRead(List<String> ids) async {
    final current = await _readLocal();
    if (current.isEmpty) return;
    final updated = current
        .map(
          (n) => ids.contains(n.id) ? n.copyWith(isRead: true) : n,
        )
        .toList();
    await _saveLocal(updated);
  }

  List<AppNotification> _mergeAndSort(
    List<AppNotification> primary,
    List<AppNotification> secondary,
  ) {
    final map = <String, AppNotification>{};
    for (final item in [...primary, ...secondary]) {
      map[item.id] = item;
    }
    final merged = map.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}
