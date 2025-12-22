import 'dart:async';

import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fura24.kz/features/client/domain/models/order_summary.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/location_error_banner.dart';
import 'package:fura24.kz/features/driver/view/widgets/driver_home_bottom_sheet.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/user_location_marker.dart';
import 'package:fura24.kz/features/client/state/tracked_cargo_notifier.dart';
import 'package:fura24.kz/features/driver/providers/driver_assigned_orders_provider.dart';
import 'package:geolocator/geolocator.dart';

import 'package:latlong2/latlong.dart';

const Distance _driverDistance = Distance();

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverHomeTab extends ConsumerStatefulWidget {
  const DriverHomeTab({super.key});

  @override
  ConsumerState<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends ConsumerState<DriverHomeTab> {
  final MapController _mapController = MapController();
  final LatLng _fallbackLocation = const LatLng(51.1694, 71.4491);
  List<_ActiveCargoInfo> _activeCargos = const [];
  ProviderSubscription<AsyncValue<List<OrderSummary>>>? _ordersSubscription;

  LatLng? _currentLocation;
  bool _isLocationLoading = false;
  bool _hasCenteredOnUser = false;
  String? _locationError;
  StreamSubscription<Position>? _positionSubscription;
  double _currentSheetExtent = _minExtent;
  bool _sheetExtentUpdateScheduled = false;
  bool _pendingMapRecenter = false;

  @override
  void initState() {
    super.initState();
    _setFullScreen();
    _currentSheetExtent = _midExtent;
    _initLocation();
    trackedCargoIdNotifier.addListener(_onTrackedCargoChanged);
    _ordersSubscription = ref.listenManual<AsyncValue<List<OrderSummary>>>(
      driverAssignedOrdersProvider,
      (previous, next) => next.whenData(_updateActiveCargos),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    trackedCargoIdNotifier.removeListener(_onTrackedCargoChanged);
    _positionSubscription?.cancel();
    _ordersSubscription?.close();
    _mapController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocationLoading = true;
      _locationError = null;
    });

    try {
      final position = await _determinePosition();
      final location = LatLng(position.latitude, position.longitude);
      _handleLocationUpdate(location, centerOnUser: true);
      _subscribeToPositionUpdates();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLocationLoading = false;
        _locationError = tr(_mapLocationError(error));
      });
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const _LocationException('driver_home_map.error.services_off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const _LocationException('driver_home_map.error.denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _LocationException('driver_home_map.error.denied_forever');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 6),
      );
    } on TimeoutException catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw const _LocationException('driver_home_map.error.no_signal');
    } catch (error) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw _LocationException(_humanizeLocationError(error));
    }
  }

  void _subscribeToPositionUpdates() {
    _positionSubscription?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        final location = LatLng(position.latitude, position.longitude);
        _handleLocationUpdate(location);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _locationError = tr(_mapLocationError(error));
        });
      },
    );
  }

  void _handleLocationUpdate(LatLng location, {bool centerOnUser = false}) {
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
      _isLocationLoading = false;
    });

    if (centerOnUser || !_hasCenteredOnUser) {
      _centerMapOn(location, 14);
      _hasCenteredOnUser = true;
    }
  }

  void _centerMapOn(LatLng target, double zoom) {
    final offset = _cameraOffsetForSheet();
    if (offset == null) {
      _mapController.move(target, zoom);
      if (_currentSheetExtent > _minExtent + 0.01) {
        _scheduleMapRecenter();
      }
      return;
    }

    final adjustedCenter = _centerWithOffset(target, zoom, offset);
    _mapController.move(adjustedCenter, zoom);
  }

  void _scheduleMapRecenter() {
    if (_pendingMapRecenter) return;
    _pendingMapRecenter = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingMapRecenter = false;
      if (!mounted || _currentLocation == null) return;
      final offset = _cameraOffsetForSheet();
      if (offset == null) {
        if (_currentSheetExtent > _minExtent + 0.01) {
          _scheduleMapRecenter();
        }
        return;
      }
      final zoom = _mapController.camera.zoom;
      final adjustedCenter = _centerWithOffset(_currentLocation!, zoom, offset);
      _mapController.move(adjustedCenter, zoom);
    });
  }

  LatLng _centerWithOffset(LatLng target, double zoom, Offset offset) {
    final camera = _mapController.camera;
    final projectedTarget = camera.project(target, zoom);
    final rotatedOffset = _rotateOffset(offset, camera.rotationRad);
    final adjustedPoint = math.Point<double>(
      projectedTarget.x - rotatedOffset.x,
      projectedTarget.y - rotatedOffset.y,
    );
    return camera.unproject(adjustedPoint, zoom);
  }

  math.Point<double> _rotateOffset(Offset offset, double rotationRad) {
    if (rotationRad == 0) {
      return math.Point<double>(offset.dx, offset.dy);
    }
    final cosR = math.cos(rotationRad);
    final sinR = math.sin(rotationRad);
    final dx = offset.dx * cosR - offset.dy * sinR;
    final dy = offset.dx * sinR + offset.dy * cosR;
    return math.Point<double>(dx, dy);
  }

  Offset? _cameraOffsetForSheet() {
    final extent = _currentSheetExtent;
    if (extent <= _minExtent + 0.01) return null;

    final camera = _mapController.camera;
    final size = camera.nonRotatedSize;
    final height = size.y;
    if (height <= 0) return null;

    final sheetHeight = height * extent;
    final visibleHeight = height - sheetHeight;
    final desiredOffset = -(sheetHeight / 2) - (visibleHeight * 0.05);
    final minShift = -(height / 2) + 24.0;
    final clamped = desiredOffset.clamp(minShift, 0.0);

    return Offset(0, clamped);
  }

  void _moveToCurrentLocation() {
    final location = _currentLocation;
    if (location != null) {
      final currentZoom = _mapController.camera.zoom;
      final targetZoom = currentZoom < 14 ? 14.0 : currentZoom;
      _centerMapOn(location, targetZoom);
    } else {
      _initLocation();
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  String _mapLocationError(Object error) {
    if (error is _LocationException) return error.message;
    return _humanizeLocationError(error);
  }

  String _humanizeLocationError(Object error) {
    if (error is PermissionDeniedException) {
      return 'driver_home_map.error.denied';
    }
    if (error is LocationServiceDisabledException) {
      return 'driver_home_map.error.services_off';
    }
    return 'driver_home_map.error.unknown';
  }

  void _updateActiveCargos(List<OrderSummary> orders) {
    final mapped =
        orders
            .where(
              (order) =>
                  order.status != CargoStatus.completed &&
                  order.status != CargoStatus.cancelled,
            )
            .map(_activeCargoFromOrder)
            .whereType<_ActiveCargoInfo>()
            .toList();

    if (!mounted) return;
    setState(() {
      _activeCargos = mapped;
      if (_activeCargos.isEmpty) {
        trackedCargoIdNotifier.value = null;
      } else if (trackedCargoIdNotifier.value != null &&
          !_activeCargos.any(
            (cargo) => cargo.id == trackedCargoIdNotifier.value,
          )) {
        trackedCargoIdNotifier.value = _activeCargos.first.id;
      } else if (trackedCargoIdNotifier.value == null) {
        trackedCargoIdNotifier.value = _activeCargos.first.id;
      }
    });
  }

  _ActiveCargoInfo? _activeCargoFromOrder(OrderSummary order) {
    final origin = _latLngOrNull(
      order.departureLatitude,
      order.departureLongitude,
    );
    final destination = _latLngOrNull(
      order.destinationLatitude,
      order.destinationLongitude,
    );
    if (origin == null || destination == null) return null;

    final waypointPoints =
        order.waypoints.toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final routePoints = <LatLng>[
      origin,
      ...waypointPoints
          .map(
            (w) => _latLngOrNull(
              _parseNum(w.location['latitude'])?.toDouble(),
              _parseNum(w.location['longitude'])?.toDouble(),
            ),
          )
          .whereType<LatLng>(),
      destination,
    ];
    final routeNames = <String>[
      order.departureCity,
      ...waypointPoints.map((w) => _cityFromLocation(w.location)),
      order.destinationCity,
    ];
    final resolvedNames = routeNames.take(routePoints.length).toList();

    return _ActiveCargoInfo(
      id: order.id,
      origin: origin,
      destination: destination,
      routePoints: routePoints,
      routeNames: resolvedNames,
      routeLabel: order.routeLabel,
      progress: _progressFromStatus(order.rawStatus, order.status),
      status: order.status,
      rawStatus: order.rawStatus,
      statusLabel: _statusLabel(order.status, order.rawStatus),
    );
  }

  LatLng? _latLngOrNull(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  double? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.trim().isNotEmpty) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  double _progressFromStatus(String rawStatus, CargoStatus status) {
    switch (rawStatus) {
      case 'WAITING_DRIVER_CONFIRMATION':
      case 'ACCEPTED':
        return 0.05;
      case 'READY_FOR_PICKUP':
        return 0.15;
      case 'WAITING_PICKUP_CONFIRMATION':
        return 0.35;
      case 'IN_PROGRESS':
        return 0.6;
      case 'WAITING_DELIVERY_CONFIRMATION':
        return 0.85;
      case 'DELIVERED':
        return 1;
    }
    switch (status) {
      case CargoStatus.pending:
        return 0.1;
      case CargoStatus.inTransit:
        return 0.6;
      case CargoStatus.completed:
        return 1;
      case CargoStatus.cancelled:
        return 0;
    }
  }

  String _statusLabel(CargoStatus status, String rawStatus) {
    switch (rawStatus) {
      case 'WAITING_DRIVER_CONFIRMATION':
        return tr('driver_home_map.status.waiting_driver_confirmation');
      case 'READY_FOR_PICKUP':
        return tr('driver_home_map.status.ready_for_pickup');
      case 'WAITING_PICKUP_CONFIRMATION':
        return tr('driver_home_map.status.waiting_pickup_confirmation');
      case 'WAITING_DELIVERY_CONFIRMATION':
        return tr('driver_home_map.status.waiting_delivery_confirmation');
    }
    switch (status) {
      case CargoStatus.pending:
        return tr('driver_home_map.status.pending');
      case CargoStatus.inTransit:
        return tr('driver_home_map.status.in_transit');
      case CargoStatus.completed:
        return tr('driver_home_map.status.completed');
      case CargoStatus.cancelled:
        return tr('driver_home_map.status.cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation =
        _currentLocation ??
        (_activeCargos.isNotEmpty
            ? _activeCargos.first.midpoint
            : _fallbackLocation);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final sheetHeight = screenHeight * _currentSheetExtent;
    final safeBottomInset = mediaQuery.padding.bottom;
    final topSafeArea = mediaQuery.padding.top;
    final bool isCollapsedSheet = _isSheetCollapsed;
    final bool isFullSheet = _currentSheetExtent >= _maxExtent - 0.01;
    final double zoomControlsHeight = (48.w * 2) + 1;
    final double locationButtonHeight = 48.w;
    final double languageButtonHeight = 48.w;
    final double controlsSpacing = 12.h;
    final double controlsColumnHeight =
        languageButtonHeight +
        controlsSpacing +
        zoomControlsHeight +
        controlsSpacing +
        locationButtonHeight;
    final double baseControlsBottom = 120.h;
    final double minControlsBottom = sheetHeight + safeBottomInset + 24.h;
    final double maxControlsBottom = math.max(
      0,
      screenHeight - topSafeArea - controlsColumnHeight - 16.h,
    );
    final double controlsBottom = math.min(
      maxControlsBottom,
      math.max(baseControlsBottom, minControlsBottom),
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: activeLocation,
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fura24.kz',
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
              ),
              if (_activeCargos.isNotEmpty)
                PolylineLayer(polylines: _buildCargoPolylines()),
              if (_activeCargos.isNotEmpty)
                MarkerLayer(markers: _buildCargoMarkers()),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.w,
                      height: 80.h,
                      point: _currentLocation!,
                      child: const UserLocationMarker(),
                      alignment: Alignment.center,
                    ),
                  ],
                ),
            ],
          ),

          if (_locationError != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16.h,
              left: 16.w,
              right: 16.w,
              child: LocationErrorBanner(
                message: _locationError!,
                onRetry: _initLocation,
              ),
            ),

          if (!isFullSheet && !isCollapsedSheet)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              bottom: controlsBottom,
              right: 16.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageButton(),
                  SizedBox(height: controlsSpacing),
                  _buildZoomControls(),
                  SizedBox(height: controlsSpacing),
                  _buildLocationButton(),
                ],
              ),
            ),

          if (isCollapsedSheet) ...[
            Positioned(
              bottom: 120.h,
              right: 16.w,
              child: _buildLocationButton(),
            ),
            Positioned(
              top: 90.h,
              right: 16.w,
              child: _buildLanguageButton(),
            ),
            Positioned(top: 300.h, right: 16.w, child: _buildZoomControls()),
          ],

          Positioned.fill(
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final extent =
                    notification.extent
                        .clamp(_minExtent, _maxExtent)
                        .toDouble();
                if ((extent - _currentSheetExtent).abs() > 0.001) {
                  setState(() {
                    _currentSheetExtent = extent;
                  });
                  if (!_sheetExtentUpdateScheduled) {
                    _sheetExtentUpdateScheduled = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _sheetExtentUpdateScheduled = false;
                      if (!mounted) return;
                      if (_isSheetCollapsed && _activeCargos.isNotEmpty) {
                        _focusOnActiveCargo(context);
                        return;
                      }
                      if (_currentLocation != null) {
                        final zoom = _mapController.camera.zoom;
                        _centerMapOn(_currentLocation!, zoom);
                      } else {
                        setState(() {});
                      }
                    });
                  }
                }
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: _midExtent,
                minChildSize: _minExtent,
                maxChildSize: _maxExtent,
                snap: true,
                snapSizes: const [_minExtent, _midExtent, _maxExtent],
                builder: (context, scrollController) {
                  return DriverHomeBottomSheet(
                    scrollController: scrollController,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isSheetCollapsed => _currentSheetExtent <= _minExtent + 0.01;

  List<Polyline> _buildCargoPolylines() {
    final trackedId = trackedCargoIdNotifier.value;
    final cargos =
        trackedId != null
            ? _activeCargos.where((c) => c.id == trackedId).toList()
            : (_activeCargos.isNotEmpty ? [_activeCargos.first] : const []);

    if (cargos.isEmpty) return const [];

    final cargo = cargos.first;
    final points =
        cargo.routePoints.length >= 2
            ? cargo.routePoints
            : <LatLng>[cargo.origin, cargo.destination];

    return [
      Polyline(
        points: points,
        strokeWidth: 4.5,
        color: const Color(0xFF00B2FF).withValues(alpha: 0.9),
      ),
    ];
  }

  List<Marker> _buildCargoMarkers() {
    final trackedId = trackedCargoIdNotifier.value;
    return _activeCargos.expand((cargo) {
      final isTracked =
          trackedId == null || trackedId == cargo.id || _isSheetCollapsed;
      if (!isTracked) return <Marker>[];

      final route =
          cargo.routePoints.isNotEmpty
              ? cargo.routePoints
              : [cargo.origin, cargo.destination];
      final markers = <Marker>[];
      for (var i = 0; i < route.length; i++) {
        final point = route[i];
        final letter = _letterForIndex(i);
        final name =
            i < cargo.routeNames.length && cargo.routeNames[i].isNotEmpty
                ? cargo.routeNames[i]
                : letter;
        final isFirst = i == 0;
        final isLast = i == route.length - 1;
        final color =
            isLast
                ? const Color(0xFF2EB872)
                : const Color(0xFF00B2FF);
        markers.add(
          Marker(
            width: 48.w,
            height: 64.h,
            point: point,
            alignment: Alignment.topCenter,
            child: _RouteLetterPin(
              letter: letter,
              subtitle: name,
              color: color,
              emphasize: isFirst || isLast,
            ),
          ),
        );
      }

      return markers;
    }).toList();
  }

  void _focusOnActiveCargo(BuildContext context) {
    final trackedId = trackedCargoIdNotifier.value;
    final selected =
        trackedId == null
            ? _activeCargos
            : _activeCargos.where((cargo) => cargo.id == trackedId).toList();
    if (selected.isEmpty) return;

    final firstCargo = selected.first;
    final combinedBounds = LatLngBounds.fromPoints(
      firstCargo.routePoints.isNotEmpty
          ? firstCargo.routePoints
          : [firstCargo.origin, firstCargo.destination],
    );

    if (_samePoint(firstCargo.origin, firstCargo.destination)) {
      _mapController.move(firstCargo.origin, 13);
      return;
    }

    for (final cargo in selected.skip(1)) {
      if (cargo.routePoints.isNotEmpty) {
        for (final p in cargo.routePoints) {
          combinedBounds.extend(p);
        }
      } else {
        combinedBounds.extend(cargo.origin);
        combinedBounds.extend(cargo.destination);
      }
    }

    final padding = EdgeInsets.only(
      top: 120.h,
      bottom: 240.h + MediaQuery.of(context).padding.bottom,
      left: 80.w,
      right: 80.w,
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: combinedBounds, padding: padding),
    );
  }

  void _onTrackedCargoChanged() {
    if (!mounted) return;
    if (_isSheetCollapsed && trackedCargoIdNotifier.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusOnActiveCargo(context);
        }
      });
    }
  }

  Widget _buildLocationButton() {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: _isLocationLoading ? null : _moveToCurrentLocation,
          child: Center(
            child:
                _isLocationLoading
                    ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                    : SvgPicture.asset(
                      'assets/svg/location-arrow.svg',
                      width: 20.w,
                      height: 20.h,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14.r),
              topRight: Radius.circular(14.r),
            ),
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
              onTap: _zoomIn,
              child: SizedBox(
                width: 48.w,
                height: 48.w,
                child: Icon(Icons.add, color: Colors.black, size: 20.w),
              ),
            ),
          ),
          Container(
            width: 32.w,
            height: 1,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(14.r),
              bottomRight: Radius.circular(14.r),
            ),
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14.r),
                bottomRight: Radius.circular(14.r),
              ),
              onTap: _zoomOut,
              child: SizedBox(
                width: 48.w,
                height: 48.w,
                child: Icon(Icons.remove, color: Colors.black, size: 20.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton() {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: _showLanguageSheet,
          child: Center(
            child: SvgPicture.asset(
              'assets/svg/world.svg',
              width: 22.w,
              height: 22.w,
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguageSheet() async {
    final current = context.locale;
    final selected = await showModalBottomSheet<_LocaleOption>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 12.h),
                ..._localeOptions.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    trailing:
                        option.locale.languageCode == current.languageCode
                            ? const Icon(Icons.radio_button_checked,
                                color: Color(0xFF64B5F6))
                            : const Icon(Icons.radio_button_off),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await context.setLocale(selected.locale);
      setState(() {});
    }
  }
}

const _localeOptions = <_LocaleOption>[
  _LocaleOption(locale: Locale('ru'), label: 'Русский'),
  _LocaleOption(locale: Locale('kk'), label: 'Қазақша'),
  _LocaleOption(locale: Locale('en'), label: 'English'),
  _LocaleOption(locale: Locale('zh'), label: '中文'),
];

const double _minExtent = 0.12;
const double _midExtent = 0.5;
const double _maxExtent = 0.9;

class _LocaleOption {
  const _LocaleOption({required this.locale, required this.label});
  final Locale locale;
  final String label;
}

class _ActiveCargoInfo {
  const _ActiveCargoInfo({
    required this.id,
    required this.origin,
    required this.destination,
    required this.routePoints,
    required this.routeNames,
    required this.routeLabel,
    required this.progress,
    required this.status,
    required this.rawStatus,
    required this.statusLabel,
  });

  final String id;
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> routePoints;
  final List<String> routeNames;
  final String routeLabel;
  final double progress;
  final CargoStatus status;
  final String rawStatus;
  final String statusLabel;

  LatLng get midpoint => LatLng(
    (origin.latitude + destination.latitude) / 2,
    (origin.longitude + destination.longitude) / 2,
  );

  LatLng get currentPosition {
    final route = routePoints.length >= 2 ? routePoints : [origin, destination];
    return _positionOnRoute(route, progress);
  }
}

bool _samePoint(LatLng a, LatLng b) {
  return (a.latitude - b.latitude).abs() < 0.0001 &&
      (a.longitude - b.longitude).abs() < 0.0001;
}

LatLng _positionOnRoute(List<LatLng> route, double t) {
  if (route.isEmpty) return const LatLng(48.0196, 66.9237);
  if (route.length == 1) return route.first;
  final clamped = t.clamp(0.0, 1.0);
  final totalLength = _routeLength(route);
  if (totalLength <= 0) return route.first;

  final target = totalLength * clamped;
  var traversed = 0.0;
  for (var i = 0; i < route.length - 1; i++) {
    final a = route[i];
    final b = route[i + 1];
    final segment = _driverDistance.distance(a, b);
    if (traversed + segment >= target) {
      final remain = target - traversed;
      final ratio = segment == 0 ? 0.0 : remain / segment;
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * ratio,
        a.longitude + (b.longitude - a.longitude) * ratio,
      );
    }
    traversed += segment;
  }
  return route.last;
}

double _routeLength(List<LatLng> route) {
  var total = 0.0;
  for (var i = 0; i < route.length - 1; i++) {
    total += _driverDistance.distance(route[i], route[i + 1]);
  }
  return total;
}

String _cityFromLocation(Map<String, dynamic>? location) {
  return (location?['city_name'] as String?)?.trim() ?? '';
}

String _letterForIndex(int index) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if (index < 0) return '';
  var n = index;
  var result = '';
  do {
    result = letters[n % 26] + result;
    n = (n ~/ 26) - 1;
  } while (n >= 0);
  return result;
}

class _RouteLetterPin extends StatelessWidget {
  const _RouteLetterPin({
    required this.letter,
    required this.subtitle,
    required this.color,
    this.emphasize = false,
  });

  final String letter;
  final String subtitle;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color, width: emphasize ? 3 : 2),
          ),
          width: emphasize ? 34.w : 30.w,
          height: emphasize ? 34.w : 30.w,
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: emphasize ? 14.sp : 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
