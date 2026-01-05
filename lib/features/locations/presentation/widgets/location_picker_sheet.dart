import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/presentation/providers/location_search_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerSelection {
  const LocationPickerSelection({
    required this.location,
    this.selectedOnMap = false,
    this.addressLabel,
  });

  final LocationModel location;
  final bool selectedOnMap;
  final String? addressLabel;
}

class _LocationException implements Exception {
  const _LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({
    super.key,
    required this.title,
    this.excludeLocationId,
  });

  final String title;
  final int? excludeLocationId;

  @override
  ConsumerState<LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();
  Timer? _debounce;
  String _query = '';
  bool _isMapLocationLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _listController.addListener(_onScroll);
  }

  void _handleSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _listController.removeListener(_onScroll);
    _listController.dispose();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(locationSearchProvider(_query));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.h),
            Material(
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: tr('locations.search_hint'),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 22.w,
                    color: Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              tr('locations.search_subtitle'),
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: _buildLocationsList(searchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList(LocationSearchState searchState) {
    if (searchState.isLoading && searchState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (searchState.error != null && searchState.items.isEmpty) {
      return Center(
        child: Text(
          searchState.error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
        ),
      );
    }

    final filtered =
        widget.excludeLocationId == null
            ? searchState.items
            : searchState.items
                .where((location) => location.id != widget.excludeLocationId)
                .toList();

    final hasHits = filtered.isNotEmpty;
    if (!hasHits) {
      return Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    final showFooter =
        searchState.hasMore || searchState.isLoadingMore || searchState.loadMoreError != null;
    final itemCount = filtered.length + (showFooter ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            final availableWithCoordinates =
                filtered
                    .where(
                      (location) =>
                          location.latitude != null &&
                          location.longitude != null,
                    )
                    .toList();
            final selected = await _showMapLocationPicker(
              availableWithCoordinates,
            );
            if (selected != null) {
              Navigator.of(context).pop(selected);
            }
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/svg/marker.svg',
                  width: 18.w,
                  height: 18.h,
                  colorFilter: const ColorFilter.mode(
                    Colors.blue,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    tr('locations.pick_on_map'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[500],
                  size: 24.w,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        Expanded(
          child: ListView.separated(
            controller: _listController,
            padding: EdgeInsets.only(top: 12.h),
            itemCount: itemCount,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              if (index >= filtered.length) {
                if (searchState.isLoadingMore) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (searchState.loadMoreError != null) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Column(
                      children: [
                        Text(
                          searchState.loadMoreError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.redAccent,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _loadMore(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final location = filtered[index];
              return ListTile(
                title: Text(
                  location.cityName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    location.country.isNotEmpty
                        ? Text(
                            location.country,
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          )
                        : location.latitude != null && location.longitude != null
                        ? Text(
                            '${location.latitude!.toStringAsFixed(3)}, '
                            '${location.longitude!.toStringAsFixed(3)}',
                            style: TextStyle(fontSize: 12.sp),
                          )
                        : null,
                onTap: () => Navigator.of(context).pop(
                  LocationPickerSelection(
                    location: location,
                    selectedOnMap: false,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onScroll() {
    if (!_listController.hasClients) return;
    final position = _listController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    ref.read(locationSearchProvider(_query).notifier).loadMore();
  }

  Future<LocationPickerSelection?> _showMapLocationPicker(
    List<LocationModel> locations,
  ) async {
    LatLng? safeLatLng(LocationModel location) {
      final lat = location.latitude;
      final lng = location.longitude;
      if (lat == null || lng == null) return null;
      if (!lat.isFinite || !lng.isFinite) return null;
      if (lat == 0 && lng == 0) return null;
      if (lat.abs() > 90 || lng.abs() > 180) return null;
      return LatLng(lat, lng);
    }

    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Нет городов с координатами для отображения на карте',
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      );
      return null;
    }

    final availableWithCoordinates =
        locations
            .where(
              (location) => safeLatLng(location) != null,
            )
            .toList();
    if (availableWithCoordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Нет городов с точными координатами'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      );
      return null;
    }

    final mapController = MapController();
    LatLng currentCenter =
        safeLatLng(availableWithCoordinates.first) ??
        const LatLng(48.0196, 66.9237);
    final distance = const Distance();
    final subscription = mapController.mapEventStream.listen((event) {
      if (event is MapEventWithMove) {
        currentCenter = event.camera.center;
      }
    });

    final result = await showModalBottomSheet<LocationPickerSelection>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
      ),
      builder: (context) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: currentCenter,
                    zoom: 6,
                    interactiveFlags:
                        InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fura24.kz',
                      retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 70.h,
                left: 16.w,
                right: 16.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    'Перемещайте карту — указатель следует за центром, затем нажмите кнопку.',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
              Positioned(
                top: 120.h,
                right: 16.w,
                child: _buildMyLocationButton(mapController),
              ),
              Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 48.w,
                ),
              ),
              Positioned(
                bottom: 24.h + MediaQuery.of(context).viewPadding.bottom,
                left: 16.w,
                right: 16.w,
                child: ElevatedButton(
                  onPressed: () async {
                    final nearest = _findNearestLocation(
                      availableWithCoordinates,
                      currentCenter,
                      distance,
                    );
                    if (nearest != null) {
                      final label = await _describeLocation(
                        currentCenter,
                        nearest,
                      );
                      Navigator.of(context).pop(
                        LocationPickerSelection(
                          location: nearest,
                          selectedOnMap: true,
                          addressLabel: label ??
                              '${nearest.cityName}, точка на карте',
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Невозможно определить ближайший город',
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    backgroundColor: const Color(0xFF1E88E5),
                  ),
                  child: Text(
                    'Выбрать точку',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    subscription.cancel();
    return result;
  }

  LocationModel? _findNearestLocation(
    List<LocationModel> locations,
    LatLng center,
    Distance distance,
  ) {
    LocationModel? best;
    double bestDistance = double.infinity;
    for (final location in locations) {
      if (location.latitude == null || location.longitude == null) continue;
      final dist = distance(
        center,
        LatLng(location.latitude!, location.longitude!),
      );
      if (dist < bestDistance) {
        bestDistance = dist;
        best = location;
      }
    }
    return best;
  }

  Widget _buildMyLocationButton(MapController mapController) {
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
          onTap: () => _onMapLocationPressed(mapController),
          child: Center(
            child: _isMapLocationLoading
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

  Future<void> _onMapLocationPressed(MapController mapController) async {
    if (_isMapLocationLoading) return;
    try {
      setState(() => _isMapLocationLoading = true);
      final position = await _determinePosition();
      final latLng = LatLng(position.latitude, position.longitude);
      mapController.move(latLng, 14);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapLocationError(error))),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isMapLocationLoading = false);
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
        'Не удалось получить текущее местоположение.',
      );
    } catch (error) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      throw _LocationException(_humanizeLocationError(error));
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

  Future<String?> _describeLocation(
    LatLng center,
    LocationModel fallback,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        center.latitude,
        center.longitude,
      );
      if (placemarks.isEmpty) return null;
      final placemark = placemarks.first;
      final city = _firstNonEmpty([
        placemark.locality,
        placemark.subAdministrativeArea,
        fallback.cityName,
      ]) ??
          fallback.cityName;
      final streetParts = <String>[];
      if (placemark.street?.trim().isNotEmpty ?? false) {
        streetParts.add(placemark.street!.trim());
      }
      if (placemark.subThoroughfare?.trim().isNotEmpty ?? false) {
        streetParts.add(placemark.subThoroughfare!.trim());
      }
      if (streetParts.isEmpty &&
          (placemark.name?.trim().isNotEmpty ?? false)) {
        streetParts.add(placemark.name!.trim());
      }
      final street = streetParts.isNotEmpty ? streetParts.join(' ') : null;
      final components = [city];
      if (street != null && street.isNotEmpty) {
        components.add(street);
      }
      return components.join(', ');
    } catch (_) {
      return null;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value?.trim().isNotEmpty ?? false) {
        return value!.trim();
      }
    }
    return null;
  }
}
