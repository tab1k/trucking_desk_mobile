import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fura24.kz/features/client/data/repositories/order_repository.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';

final driverLocationSharingProvider = Provider<DriverLocationSharingService>((ref) {
  final service = DriverLocationSharingService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class DriverLocationSharingService {
  DriverLocationSharingService(this._ref);

  static const Duration _defaultInterval = Duration(hours: 1);
  static const Duration _localInterval = Duration(minutes: 10);

  final Ref _ref;
  Timer? _timer;
  Duration _currentInterval = _defaultInterval;
  List<String> _orderIds = const [];
  bool _isSending = false;

  void updateOrders(List<OrderSummary> orders) {
    final trackable = orders.where(_isTrackable).toList();
    final ids = trackable.map((order) => order.id).toList();
    final newInterval = _determineInterval(trackable);

    if (listEquals(ids, _orderIds) && newInterval == _currentInterval) {
      return;
    }

    _orderIds = ids;
    _currentInterval = newInterval;
    _restartTimer();
  }

  bool _isTrackable(OrderSummary order) {
    return order.driverId != null &&
        order.driverId!.isNotEmpty &&
        order.status != CargoStatus.completed &&
        order.status != CargoStatus.cancelled;
  }

  Duration _determineInterval(List<OrderSummary> orders) {
    final hasLocalRoute = orders.any((order) {
      final from = (order.departureCity).trim().toLowerCase();
      final to = (order.destinationCity).trim().toLowerCase();
      if (from.isEmpty || to.isEmpty) return false;
      return from == to;
    });
    return hasLocalRoute ? _localInterval : _defaultInterval;
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_orderIds.isEmpty) return;
    _timer = Timer.periodic(_currentInterval, (_) => _tick());
    _tick();
  }

  Future<void> _tick() async {
    if (_isSending || _orderIds.isEmpty) return;
    final position = await _resolvePosition();
    if (position == null) return;
    _isSending = true;
    try {
      final repo = _ref.read(orderRepositoryProvider);
      final reportedAt = DateTime.now();
      for (final orderId in _orderIds) {
        try {
          await repo.submitDriverLocation(
            orderId,
            latitude: position.latitude,
            longitude: position.longitude,
            reportedAt: reportedAt,
          );
        } catch (_) {
          // Ignore errors for individual orders to avoid interrupting the loop.
        }
      }
    } finally {
      _isSending = false;
    }
  }

  Future<Position?> _resolvePosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
