import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/features/client/state/tracked_cargo_notifier.dart';
import 'package:fura24.kz/features/client/presentation/providers/home_tab_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class MyCargoTab extends ConsumerStatefulWidget {
  const MyCargoTab({super.key});

  @override
  ConsumerState<MyCargoTab> createState() => _MyCargoTabState();
}

class _MyCargoTabState extends ConsumerState<MyCargoTab> {
  int _currentFilterIndex = 0;
  final List<String> _filters = ['Все', 'Активные', 'Завершенные', 'Отмененные'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SingleAppbar(
        title: 'Мои грузы',
      ),
      body: Column(
        children: [
          // Фильтры
          _buildFilterChips(),
          SizedBox(height: 16.h),
          
          // Список грузов
          Expanded(
            child: _buildCargoList(),
          ),
        ],
      ),
      // Кнопка создания нового груза - поднята выше
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 65.h), // Поднимаем над bottom navbar
        child: FloatingActionButton(
          onPressed: () {
            // Навигация на страницу создания груза
          },
          backgroundColor: Color(0xFF64B5F6), // Новый цвет
          elevation: 4,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 24.w,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: CupertinoButton(
              onPressed: () {
                setState(() {
                  _currentFilterIndex = index;
                });
              },
              color: _currentFilterIndex == index 
                  ? Color(0xFF64B5F6) // Новый цвет
                  : CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(20.r),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minSize: 0,
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: _currentFilterIndex == index 
                      ? Colors.white 
                      : CupertinoColors.systemGrey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCargoList() {
    final List<CargoItem> cargoItems = [
      CargoItem(
        id: 'CARGO-001',
        title: 'Оборудование для офиса',
        route: 'Алматы → Нур-Султан',
        weight: '500 кг',
        volume: '2.5 м³',
        price: '45 000 ₸',
        status: CargoStatus.inTransit,
        date: 'Сегодня, 14:30',
      ),
      CargoItem(
        id: 'CARGO-002',
        title: 'Мебель для квартиры',
        route: 'Шымкент → Актобе',
        weight: '1200 кг',
        volume: '8.0 м³',
        price: '75 000 ₸',
        status: CargoStatus.completed,
        date: 'Вчера, 10:15',
      ),
      CargoItem(
        id: 'CARGO-003',
        title: 'Электроника и техника',
        route: 'Атырау → Караганда',
        weight: '300 кг',
        volume: '1.5 м³',
        price: '35 000 ₸',
        status: CargoStatus.pending,
        date: 'Завтра, 09:00',
      ),
      CargoItem(
        id: 'CARGO-004',
        title: 'Строительные материалы',
        route: 'Астана → Алматы',
        weight: '2000 кг',
        volume: '12.0 м³',
        price: '120 000 ₸',
        status: CargoStatus.cancelled,
        date: '15 дек, 16:45',
      ),
    ];

    // Фильтрация по выбранному фильтру
    final filteredItems = _currentFilterIndex == 0 
        ? cargoItems 
        : cargoItems.where((item) {
            switch (_currentFilterIndex) {
              case 1: return item.status == CargoStatus.inTransit || item.status == CargoStatus.pending;
              case 2: return item.status == CargoStatus.completed;
              case 3: return item.status == CargoStatus.cancelled;
              default: return true;
            }
          }).toList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final cargo = filteredItems[index];
        return _CargoListItem(cargo: cargo);
      },
    );
  }
}

enum CargoStatus {
  pending,
  inTransit,
  completed,
  cancelled,
}

class CargoItem {
  final String id;
  final String title;
  final String route;
  final String weight;
  final String volume;
  final String price;
  final CargoStatus status;
  final String date;

  CargoItem({
    required this.id,
    required this.title,
    required this.route,
    required this.weight,
    required this.volume,
    required this.price,
    required this.status,
    required this.date,
  });
}

class _CargoListItem extends ConsumerWidget {
  final CargoItem cargo;

  const _CargoListItem({required this.cargo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок и статус
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cargo.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(cargo.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _getStatusText(cargo.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _getStatusColor(cargo.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // ID груза
          Text(
            cargo.id,
            style: TextStyle(
              fontSize: 12.sp,
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),
          
          // Маршрут
          Row(
            children: [
              SvgPicture.asset(
                'assets/svg/marker.svg',
                width: 16.w,
                height: 16.w,
                colorFilter: ColorFilter.mode(
                  Color(0xFF64B5F6), // Новый цвет
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  cargo.route,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF1A1D1F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // Характеристики груза
          Row(
            children: [
              _CargoSpecItem(
                iconPath: 'assets/svg/wei.svg',
                value: cargo.weight,
              ),
              SizedBox(width: 16.w),
              _CargoSpecItem(
                iconPath: 'assets/svg/ruler.svg',
                value: cargo.volume,
              ),
              Spacer(),
              Text(
                cargo.price,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64B5F6), // Новый цвет
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Дата и действия
          Row(
            children: [
              Text(
                cargo.date,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Spacer(),
              if (cargo.status == CargoStatus.pending || cargo.status == CargoStatus.inTransit)
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: () {
                        trackedCargoIdNotifier.value = cargo.id;
                        ref.read(homeTabIndexProvider.notifier).state = 0;
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      child: Text(
                        'Отследить',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xFF64B5F6), // Новый цвет
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    CupertinoButton(
                      onPressed: () {
                        // Действие с грузом
                      },
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      child: Text(
                        'Изменить',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xFF64B5F6), // Новый цвет
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              if (cargo.status == CargoStatus.completed)
                CupertinoButton(
                  onPressed: () {
                    // Повторить заказ
                  },
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  child: Text(
                    'Повторить',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color(0xFF64B5F6), // Новый цвет
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return Color(0xFFFF6B00);
      case CargoStatus.inTransit:
        return Color(0xFF64B5F6); // Новый цвет
      case CargoStatus.completed:
        return Color(0xFF00C968);
      case CargoStatus.cancelled:
        return Color(0xFFFF4757);
    }
  }

  String _getStatusText(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return 'Ожидание';
      case CargoStatus.inTransit:
        return 'В пути';
      case CargoStatus.completed:
        return 'Завершен';
      case CargoStatus.cancelled:
        return 'Отменен';
    }
  }
}

class _CargoSpecItem extends StatelessWidget {
  final String iconPath;
  final String value;

  const _CargoSpecItem({
    required this.iconPath,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 16.w,
          height: 16.w,
          colorFilter: ColorFilter.mode(
            Color(0xFF64B5F6), // Новый цвет
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: CupertinoColors.systemGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


class CargoTrackingPage extends StatelessWidget {
  const CargoTrackingPage({super.key, required this.cargo});

  final CargoItem cargo;

  @override
  Widget build(BuildContext context) {
    final simulation = _RouteSimulationData.forRoute(cargo.route);
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: simulation.mapCenter,
                initialZoom: simulation.zoom,
                interactionOptions: const InteractionOptions(
                  flags: ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fura24.kz',
                  retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                  tileBuilder: (context, tileWidget, tile) {
                    if (tile.loadError) {
                      return const _OfflineTilePlaceholder();
                    }
                    return tileWidget;
                  },
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: simulation.path,
                      strokeWidth: 6,
                      color: const Color(0xFF00B2FF),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: simulation.origin,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const _MapMarker(
                        icon: Icons.flag_circle,
                        color: Color(0xFF00B2FF),
                        label: 'Старт',
                      ),
                    ),
                    Marker(
                      point: simulation.destination,
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const _MapMarker(
                        icon: Icons.check_circle,
                        color: Color(0xFF2EB872),
                        label: 'Назначение',
                      ),
                    ),
                    Marker(
                      point: simulation.current,
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      child: _MovingTruckMarker(progress: simulation.progress),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: safeTop + 12.h,
            left: 16.w,
            right: 16.w,
            child: _TopOverlay(
              cargo: cargo,
              statusColor: _statusColor(cargo.status),
              statusText: _statusText(cargo.status),
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.24,
            maxChildSize: 0.65,
            snap: true,
            snapSizes: const [0.32, 0.5],
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, MediaQuery.of(context).padding.bottom + 24.h),
                    child: _TrackingSheetContent(
                      cargo: cargo,
                      simulation: simulation,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _statusColor(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return const Color(0xFFFF6B00);
      case CargoStatus.inTransit:
        return const Color(0xFF64B5F6);
      case CargoStatus.completed:
        return const Color(0xFF00C968);
      case CargoStatus.cancelled:
        return const Color(0xFFFF4757);
    }
  }

  String _statusText(CargoStatus status) {
    switch (status) {
      case CargoStatus.pending:
        return 'Ожидание';
      case CargoStatus.inTransit:
        return 'В пути';
      case CargoStatus.completed:
        return 'Завершен';
      case CargoStatus.cancelled:
        return 'Отменен';
    }
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.onBack,
    required this.cargo,
    required this.statusColor,
    required this.statusText,
  });

  final VoidCallback onBack;
  final CargoItem cargo;
  final Color statusColor;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Material(
            color: Colors.grey[200],
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cargo.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  cargo.route,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingSheetContent extends StatelessWidget {
  const _TrackingSheetContent({required this.cargo, required this.simulation});

  final CargoItem cargo;
  final _RouteSimulationData simulation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Осталось в пути',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.timer,
                label: 'Время',
                value: simulation.remainingTime,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _InfoChip(
                icon: Icons.social_distance,
                label: 'Дистанция',
                value: simulation.distanceLeft,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Text(
          'Прогресс доставки',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: simulation.progress,
            minHeight: 6.h,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00B2FF)),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Отправлено: ${simulation.departedAt}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            Text(
              'Планово: ${simulation.arrivalEta}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          'Данные груза',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.inventory_2,
                label: 'Вес',
                value: cargo.weight,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _InfoChip(
                icon: Icons.aspect_ratio,
                label: 'Объем',
                value: cargo.volume,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _InfoChip(
                icon: Icons.payments,
                label: 'Ставка',
                value: cargo.price,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        _RouteTimeline(simulation: simulation),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: const Color(0xFF00B2FF)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  const _RouteTimeline({required this.simulation});

  final _RouteSimulationData simulation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const _TimelineDot(color: Color(0xFF00B2FF)),
                Container(
                  width: 2,
                  height: 32.h,
                  color: const Color(0xFF00B2FF).withValues(alpha: 0.3),
                ),
                const _TimelineDot(color: Color(0xFF2EB872)),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Погрузка',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    simulation.departedAt,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Доставка',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    simulation.arrivalEta,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _OfflineTilePlaceholder extends StatelessWidget {
  const _OfflineTilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.grey[500], size: 24.w),
          SizedBox(height: 6.h),
          Text(
            'Нет связи с картой',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.w,
      height: 40.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(4.w),
            child: Icon(icon, size: 18.w, color: color),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovingTruckMarker extends StatelessWidget {
  const _MovingTruckMarker({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(8.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 38.w,
            height: 38.w,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00B2FF)),
            ),
          ),
          const Icon(Icons.local_shipping, color: Color(0xFF00B2FF), size: 20),
        ],
      ),
    );
  }
}

class _RouteSimulationData {
  const _RouteSimulationData({
    required this.origin,
    required this.destination,
    required this.path,
    required this.current,
    required this.progress,
    required this.remainingTime,
    required this.distanceLeft,
    required this.departedAt,
    required this.arrivalEta,
  });

  final LatLng origin;
  final LatLng destination;
  final List<LatLng> path;
  final LatLng current;
  final double progress;
  final String remainingTime;
  final String distanceLeft;
  final String departedAt;
  final String arrivalEta;

  LatLng get mapCenter => LatLng(
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      );

  double get zoom => 5.5;

  static _RouteSimulationData forRoute(String route) {
    switch (route) {
      case 'Алматы → Нур-Султан':
        return _RouteSimulationData(
          origin: LatLng(43.2389, 76.8897),
          destination: LatLng(51.1694, 71.4491),
          path: [
            LatLng(43.2389, 76.8897),
            LatLng(45.0, 74.5),
            LatLng(47.2, 73.1),
            LatLng(49.5, 72.2),
            LatLng(51.1694, 71.4491),
          ],
          current: LatLng(47.2, 73.1),
          progress: 0.58,
          remainingTime: '5 ч 20 мин',
          distanceLeft: '310 км',
          departedAt: 'Сегодня, 08:40',
          arrivalEta: 'Сегодня, 19:30',
        );
      case 'Шымкент → Актобе':
        return _RouteSimulationData(
          origin: LatLng(42.3167, 69.5958),
          destination: LatLng(50.2839, 57.1670),
          path: [
            LatLng(42.3167, 69.5958),
            LatLng(44.9, 65.2),
            LatLng(47.5, 61.4),
            LatLng(49.0, 59.2),
            LatLng(50.2839, 57.1670),
          ],
          current: LatLng(47.5, 61.4),
          progress: 0.72,
          remainingTime: '4 ч 10 мин',
          distanceLeft: '220 км',
          departedAt: 'Сегодня, 06:15',
          arrivalEta: 'Сегодня, 17:00',
        );
      case 'Атырау → Караганда':
        return _RouteSimulationData(
          origin: LatLng(47.0945, 51.9233),
          destination: LatLng(49.8028, 73.0875),
          path: [
            LatLng(47.0945, 51.9233),
            LatLng(47.8, 55.0),
            LatLng(48.6, 60.2),
            LatLng(49.1, 66.4),
            LatLng(49.8028, 73.0875),
          ],
          current: LatLng(48.6, 60.2),
          progress: 0.46,
          remainingTime: '7 ч 35 мин',
          distanceLeft: '480 км',
          departedAt: 'Сегодня, 05:50',
          arrivalEta: 'Сегодня, 20:40',
        );
      case 'Астана → Алматы':
        return _RouteSimulationData(
          origin: LatLng(51.1694, 71.4491),
          destination: LatLng(43.2389, 76.8897),
          path: [
            LatLng(51.1694, 71.4491),
            LatLng(49.2, 72.1),
            LatLng(47.3, 73.4),
            LatLng(45.5, 75.1),
            LatLng(43.2389, 76.8897),
          ],
          current: LatLng(47.3, 73.4),
          progress: 0.64,
          remainingTime: '6 ч 05 мин',
          distanceLeft: '360 км',
          departedAt: 'Сегодня, 07:30',
          arrivalEta: 'Сегодня, 20:10',
        );
      default:
        return _RouteSimulationData(
          origin: LatLng(51.1694, 71.4491),
          destination: LatLng(43.2389, 76.8897),
          path: [
            LatLng(51.1694, 71.4491),
            LatLng(47.3, 73.4),
            LatLng(43.2389, 76.8897),
          ],
          current: LatLng(47.3, 73.4),
          progress: 0.5,
          remainingTime: '6 ч 00 мин',
          distanceLeft: '350 км',
          departedAt: 'Сегодня, 08:00',
          arrivalEta: 'Сегодня, 20:00',
        );
    }
  }
}
