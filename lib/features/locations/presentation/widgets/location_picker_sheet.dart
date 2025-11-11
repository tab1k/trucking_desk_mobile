import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/locations/presentation/providers/location_search_provider.dart';

class LocationPickerSheet extends ConsumerStatefulWidget {
  const LocationPickerSheet({
    super.key,
    required this.title,
    this.excludeLocationId,
  });

  final String title;
  final int? excludeLocationId;

  @override
  ConsumerState<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
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
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationSearchProvider(_query));

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
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск города',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: locationsAsync.when(
                data: (locations) {
                  final filtered = widget.excludeLocationId == null
                      ? locations
                      : locations
                          .where((location) => location.id != widget.excludeLocationId)
                          .toList();

                  if (filtered.isEmpty) {
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

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final location = filtered[index];
                      return ListTile(
                        title: Text(location.cityName),
                        subtitle: location.latitude != null && location.longitude != null
                            ? Text(
                                '${location.latitude!.toStringAsFixed(3)}, '
                                '${location.longitude!.toStringAsFixed(3)}',
                                style: TextStyle(fontSize: 12.sp),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(location),
                      );
                    },
                  );
                },
                error: (error, __) => Center(
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
