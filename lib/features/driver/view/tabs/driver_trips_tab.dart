import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class DriverTripsTab extends StatelessWidget {
  const DriverTripsTab({super.key});

  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const List<_DriverTrip> _activeTrips = [
    _DriverTrip(
      title: 'Алматы → Астана',
      cargo: 'Фрукты, 18 палет · 21 т',
      status: 'В пути',
      statusColor: Color(0xFF0F9D58),
      eta: 'ETA 18:30',
      checkpoints: ['Каскелен', 'Темиртау', 'Астана'],
      note: 'Обновляйте статус каждые 2 часа',
    ),
    _DriverTrip(
      title: 'Капшагай → Караганда',
      cargo: 'Стройматериалы · 16 т',
      status: 'Ожидает выезда',
      statusColor: Color(0xFFFFA000),
      eta: 'Старт завтра в 07:30',
      checkpoints: ['Караганда'],
      note: 'Забрать сопроводительные документы утром',
    ),
  ];

  static const List<_DriverTrip> _historyTrips = [
    _DriverTrip(
      title: 'Шымкент → Алматы',
      cargo: 'Текстиль · 12 т',
      status: 'Доставлено',
      statusColor: Color(0xFF0065FF),
      eta: '29 янв · 19:10',
      checkpoints: ['Тараз', 'Алматы'],
      note: 'Получена премия за раннюю доставку',
    ),
    _DriverTrip(
      title: 'Алматы → Тараз',
      cargo: 'Лекарства · 8 т',
      status: 'Доставлено',
      statusColor: Color(0xFF0065FF),
      eta: '22 янв · 16:40',
      checkpoints: ['Алматы', 'Тараз'],
      note: 'Клиент оставил отзыв ★★★★★',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const SingleAppbar(title: 'Рейсы'),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        physics: const BouncingScrollPhysics(),
        children: [
          

          ..._activeTrips.map((trip) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: _DriverTripCard(trip: trip),
              )),
          SizedBox(height: 16.h),
          Text(
            'История',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 14.h),
          ..._historyTrips.map((trip) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: _DriverTripCard(trip: trip, isHistory: true),
              )),
        ],
      ),
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  const _DriverTripCard({required this.trip, this.isHistory = false});

  final _DriverTrip trip;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 24.w,
                  color: const Color(0xFF0065FF),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      trip.cargo,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: trip.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trip.status,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: trip.statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0065FF),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 2.w,
                    height: 34.h,
                    color: Colors.black.withOpacity(0.08),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0065FF),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Контрольные точки',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: trip.checkpoints
                          .map(
                            (checkpoint) => Chip(
                              backgroundColor: const Color(0xFFF0F3F7),
                              side: BorderSide.none,
                              label: Text(
                                checkpoint,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.grey[600],
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                trip.eta,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 18.w,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    trip.note,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    isHistory ? 'Детали рейса' : 'Обновить статус',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    isHistory ? 'Повторить маршрут' : 'Открыть маршрут',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverTrip {
  const _DriverTrip({
    required this.title,
    required this.cargo,
    required this.status,
    required this.statusColor,
    required this.eta,
    required this.checkpoints,
    required this.note,
  });

  final String title;
  final String cargo;
  final String status;
  final Color statusColor;
  final String eta;
  final List<String> checkpoints;
  final String note;
}
