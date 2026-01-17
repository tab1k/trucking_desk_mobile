import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/features/driver/domain/models/saved_route.dart';
import 'package:fura24.kz/features/driver/providers/saved_routes_provider.dart';

class SavedRoutesSheet extends ConsumerWidget {
  const SavedRoutesSheet({super.key, this.type});

  final String? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedRoutesAsync = ref.watch(savedRoutesProvider(type));

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            height: 4.h,
            width: 48.w,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Сохраненные маршруты',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Expanded(
            child: savedRoutesAsync.when(
              data: (allRoutes) {
                final routes = type == null
                    ? allRoutes
                    : allRoutes.where((r) => r.type == type).toList();

                if (routes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 48.w,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'У вас пока нет сохраненных маршрутов',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.only(
                    top: 8.h,
                    bottom: MediaQuery.of(context).padding.bottom + 16.h,
                  ),
                  itemCount: routes.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return Dismissible(
                      key: ValueKey(route.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red[50],
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 16.w),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                        ),
                      ),
                      onDismissed: (_) {
                        ref
                            .read(savedRoutesProvider(type).notifier)
                            .delete(route.id);
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        title: Row(
                          children: [
                            Text(
                              route.departureCityName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              route.destinationCityName,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                        onTap: () {
                          Navigator.of(context).pop(route);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Ошибка загрузки',
                  style: TextStyle(color: Colors.red[400]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<SavedRoute?> showSavedRoutesSheet(BuildContext context, {String? type}) {
  return showModalBottomSheet<SavedRoute>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SavedRoutesSheet(type: type),
  );
}
