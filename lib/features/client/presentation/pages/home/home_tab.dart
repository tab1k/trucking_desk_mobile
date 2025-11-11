import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/models/home_quick_action.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/create_order_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/history_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/subpages/find_transport_page.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/home_bottom_sheet.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/location_error_banner.dart';
import 'package:fura24.kz/features/client/presentation/pages/home/widgets/user_location_marker.dart';
import 'package:fura24.kz/features/client/state/tracked_cargo_notifier.dart';
import 'package:fura24.kz/router/utils/navigation_utils.dart';
import 'package:geolocator/geolocator.dart';

import 'package:latlong2/latlong.dart';

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final MapController _mapController = MapController();
  final LatLng _fallbackLocation = const LatLng(51.1694, 71.4491);
  final List<_ActiveCargoInfo> _activeCargos = const [
    _ActiveCargoInfo(
      id: 'CARGO-001',
      origin: LatLng(43.2389, 76.8897),
      destination: LatLng(51.1694, 71.4491),
      routeLabel: 'Алматы → Астана',
      progress: 0.58,
    ),
    _ActiveCargoInfo(
      id: 'CARGO-1520',
      origin: LatLng(42.3167, 69.5958),
      destination: LatLng(50.2839, 57.1670),
      routeLabel: 'Шымкент → Актобе',
      progress: 0.35,
    ),
  ];

  LatLng? _currentLocation;
  bool _isLocationLoading = false;
  bool _hasCenteredOnUser = false;
  String? _locationError;
  StreamSubscription<Position>? _positionSubscription;
  double _currentSheetExtent = _minExtent;
  bool _sheetExtentUpdateScheduled = false;
  bool _pendingMapRecenter = false;
  bool _showActiveOverlay = true;
  final ValueNotifier<String?> _trackedCargoId = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _setFullScreen();
    _currentSheetExtent = _midExtent;
    _initLocation();
    trackedCargoIdNotifier.addListener(_onTrackedCargoChanged);
  }

  @override
  void dispose() {
    trackedCargoIdNotifier.removeListener(_onTrackedCargoChanged);
    _positionSubscription?.cancel();
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
        _locationError = _mapLocationError(error);
      });
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const _LocationException(
        'Службы геолокации отключены. Включите GPS и попробуйте снова.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const _LocationException(
        'Доступ к геолокации отклонён. Разрешите приложению использовать GPS.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const _LocationException(
        'Доступ к геолокации заблокирован. Разрешите его в настройках устройства.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 6),
      );
    } on TimeoutException catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw const _LocationException(
        'Не удалось получить текущее местоположение. Проверьте GPS и попробуйте снова.',
      );
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
          _locationError = _mapLocationError(error);
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

  void _handleQuickAction(HomeQuickAction action) {
    switch (action) {
      case HomeQuickAction.createOrder:
        NavigationUtils.navigateWithBottomSheetAnimation(
          context,
          const CreateOrderPage(),
        );
        break;
      case HomeQuickAction.findRide:
        NavigationUtils.navigateWithBottomSheetAnimation(
          context,
          const FindTransportPage(),
        );
        break;
      case HomeQuickAction.myCargo:
        _trackedCargoId.value = _activeCargos.isNotEmpty ? _activeCargos.first.id : null;
        setState(() {
          _showActiveOverlay = true;
        });
        break;
      case HomeQuickAction.history:
        NavigationUtils.navigateWithBottomSheetAnimation(
          context,
          const HistoryPage(),
        );
        break;
    }
  }

  String _mapLocationError(Object error) {
    if (error is _LocationException) return error.message;
    return _humanizeLocationError(error);
  }

  String _humanizeLocationError(Object error) {
    if (error is PermissionDeniedException) {
      return 'Доступ к геолокации отклонён. Разрешите его в настройках устройства.';
    }
    if (error is LocationServiceDisabledException) {
      return 'Службы геолокации отключены. Включите GPS и попробуйте снова.';
    }
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return 'Не удалось определить местоположение.';
  }

  @override
  Widget build(BuildContext context) {
    final activeLocation = _currentLocation ?? (_activeCargos.isNotEmpty ? _activeCargos.first.midpoint : _fallbackLocation);
    final trackedId = trackedCargoIdNotifier.value;
    final overlayCargos = trackedId == null
        ? _activeCargos
        : _activeCargos.where((cargo) => cargo.id == trackedId).toList();

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
                PolylineLayer(
                  polylines: _buildCargoPolylines(),
                ),
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

          if (_showActiveOverlay && !_isSheetCollapsed && overlayCargos.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + (_locationError != null ? 96.h : 16.h),
              left: 16.w,
              right: 16.w,
              child: _ActiveCargoOverlay(
                cargos: overlayCargos,
                onClose: () {
                  trackedCargoIdNotifier.value = null;
                  setState(() {
                    _showActiveOverlay = false;
                  });
                },
              ),
            ),

          Positioned(bottom: 120.h, right: 16.w, child: _buildLocationButton()),

          Positioned(top: 300.h, right: 16.w, child: _buildZoomControls()),

          Positioned.fill(
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                final extent =
                    notification.extent
                        .clamp(_minExtent, _maxExtent)
                        .toDouble();
                if ((extent - _currentSheetExtent).abs() > 0.001) {
                  _currentSheetExtent = extent;
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
                  return HomeBottomSheet(
                    scrollController: scrollController,
                    onQuickActionSelected: _handleQuickAction,
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
    return _activeCargos.expand((cargo) {
      final progressPoint = cargo.currentPosition;
      final baseLine = Polyline(
        points: [cargo.origin, cargo.destination],
        strokeWidth: 4,
        color: const Color(0xFF0B1220).withOpacity(0.15),
      );

      final progressLine = Polyline(
        points: [cargo.origin, progressPoint],
        strokeWidth: 5.5,
        color: const Color(0xFF00B2FF).withOpacity(0.85),
      );

      final remainingLine = Polyline(
        points: [progressPoint, cargo.destination],
        strokeWidth: 4.5,
        color: const Color(0xFF00B2FF).withOpacity(0.25),
      );

      final isTracked = trackedId == null || trackedId == cargo.id;

      return [
        baseLine,
        if (isTracked) progressLine,
        if (isTracked) remainingLine,
      ];
    }).toList();
  }

  List<Marker> _buildCargoMarkers() {
    final trackedId = trackedCargoIdNotifier.value;
    return _activeCargos.expand((cargo) {
      final markers = <Marker>[
        Marker(
          width: 48.w,
          height: 64.h,
          point: cargo.origin,
          alignment: Alignment.topCenter,
          child: _CargoMapPin(
            assetPath: 'assets/svg/a.svg',
            label: 'Старт',
            color: const Color(0xFF00B2FF),
          ),
        ),
        Marker(
          width: 48.w,
          height: 64.h,
          point: cargo.destination,
          alignment: Alignment.topCenter,
          child: _CargoMapPin(
            assetPath: 'assets/svg/b.svg',
            label: 'Финиш',
            color: const Color(0xFF2EB872),
          ),
        ),
      ];

      final shouldShowTruck =
          trackedId == null || trackedId == cargo.id || _isSheetCollapsed;
      if (shouldShowTruck) {
        markers.add(
          Marker(
            width: 56.w,
            height: 56.w,
            point: cargo.currentPosition,
            alignment: Alignment.center,
            child: const _ActiveCargoTruckMarker(),
          ),
        );
      }

      return markers;
    }).toList();
  }

  void _focusOnActiveCargo(BuildContext context) {
    final trackedId = trackedCargoIdNotifier.value;
    final selected = trackedId == null
        ? _activeCargos
        : _activeCargos.where((cargo) => cargo.id == trackedId).toList();
    if (selected.isEmpty) return;

    final firstCargo = selected.first;
    final combinedBounds = LatLngBounds.fromPoints([
      firstCargo.origin,
      firstCargo.destination,
    ]);

    for (final cargo in selected.skip(1)) {
      combinedBounds.extend(cargo.origin);
      combinedBounds.extend(cargo.destination);
    }

    final padding = EdgeInsets.only(
      top: 120.h,
      bottom: 240.h + MediaQuery.of(context).padding.bottom,
      left: 80.w,
      right: 80.w,
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: combinedBounds,
        padding: padding,
      ),
    );
  }

  void _onTrackedCargoChanged() {
    if (!mounted) return;
    setState(() {
      if (trackedCargoIdNotifier.value != null) {
        _showActiveOverlay = true;
      }
    });
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
        borderRadius: BorderRadius.circular(50.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(50.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(50.r),
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
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
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
            color: Colors.grey.withOpacity(0.3),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
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
}

const double _minExtent = 0.12;
const double _midExtent = 0.5;
const double _maxExtent = 0.9;


class _ActiveCargoOverlay extends StatelessWidget {
  const _ActiveCargoOverlay({required this.cargos, required this.onClose});

  final List<_ActiveCargoInfo> cargos;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (cargos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Активные грузы',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close, size: 18.w, color: Colors.grey[500]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _ActiveCargoCard(info: cargos.first, onClose: onClose),
          
        ],
      ),
    );
  }
}

class _ActiveCargoCard extends StatelessWidget {
  const _ActiveCargoCard({required this.info, required this.onClose});

  final _ActiveCargoInfo info;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: const Color(0xFF00B2FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.local_shipping, color: const Color(0xFF00B2FF), size: 22.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.id,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  info.routeLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
            
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'В пути',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00B2FF),
                ),
              ),
              
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveCargoInfo {
  const _ActiveCargoInfo({
    required this.id,
    required this.origin,
    required this.destination,
    required this.routeLabel,
    required this.progress,
  });

  final String id;
  final LatLng origin;
  final LatLng destination;
  final String routeLabel;
  final double progress;

  LatLng get midpoint => LatLng(
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      );

  LatLng get currentPosition {
    final t = progress.clamp(0.0, 1.0);
    return LatLng(
      origin.latitude + (destination.latitude - origin.latitude) * t,
      origin.longitude + (destination.longitude - origin.longitude) * t,
    );
  }
}

class _CargoMapPin extends StatelessWidget {
  const _CargoMapPin({
    this.icon,
    this.assetPath,
    required this.label,
    required this.color,
  }) : assert(icon != null || assetPath != null, 'Provide either icon or assetPath');

  final IconData? icon;
  final String? assetPath;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(6.w),
          child: assetPath != null
              ? SvgPicture.asset(
                  assetPath!,
                  width: 18.w,
                  height: 18.w,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              : Icon(icon, size: 18.w, color: color),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveCargoTruckMarker extends StatelessWidget {
  const _ActiveCargoTruckMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.local_shipping, color: const Color(0xFF00B2FF), size: 25.w),
    );
  }
}
