import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class DriverFinancesTab extends StatelessWidget {
  const DriverFinancesTab({super.key});

  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const List<_DriverPayment> _upcomingPayments = [
    _DriverPayment(
      title: 'Рейс Алматы → Астана',
      amount: '275 000 ₸',
      dueDate: 'Оплата 31 янв',
      statusColor: Color(0xFF0F9D58),
    ),
    _DriverPayment(
      title: 'Рейс Шымкент → Алматы',
      amount: '198 500 ₸',
      dueDate: 'Оплата 2 фев',
      statusColor: Color(0xFFFFA000),
    ),
  ];

  static const List<_DriverExpense> _recentExpenses = [
    _DriverExpense(
      title: 'Заправка дизель',
      amount: '36 800 ₸',
      place: 'QazaqOil · Темиртау',
      time: 'Сегодня, 13:40',
      icon: Icons.local_gas_station_outlined,
    ),
    _DriverExpense(
      title: 'Платная дорога',
      amount: '1 200 ₸',
      place: 'Алматы → Каскелен',
      time: 'Сегодня, 09:30',
      icon: Icons.toll_outlined,
    ),
    _DriverExpense(
      title: 'Стоянка',
      amount: '2 600 ₸',
      place: 'Арыстан RestPoint',
      time: 'Вчера, 22:15',
      icon: Icons.local_parking_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const SingleAppbar(title: 'Кошелек'),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        physics: const BouncingScrollPhysics(),
        children: [
          _MonthlySummary(),
          SizedBox(height: 24.h),
          Text(
            'Предстоящие выплаты',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 14.h),
          ..._upcomingPayments.map(
            (payment) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _UpcomingPaymentCard(payment: payment),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Последние расходы',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 14.h),
          ..._recentExpenses.map(
            (expense) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _ExpenseTile(expense: expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0065FF), Color(0xFF00B2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0065FF).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Итоги января',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '1 320 500 ₸',
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.trending_up,
                  label: 'Доход',
                  value: '1 820 000 ₸',
                  iconBackground: Colors.white.withOpacity(0.15),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.trending_down,
                  label: 'Расходы',
                  value: '499 500 ₸',
                  iconBackground: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22.w,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '4 оплаченных рейса · +18% к среднему показателю',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.95),
                    ),
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

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBackground,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(icon, color: Colors.white, size: 22.w),
        ),
        SizedBox(height: 12.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _UpcomingPaymentCard extends StatelessWidget {
  const _UpcomingPaymentCard({required this.payment});

  final _DriverPayment payment;

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
                  Icons.payments_outlined,
                  color: const Color(0xFF0065FF),
                  size: 22.w,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      payment.dueDate,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                payment.amount,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: payment.statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: Colors.grey[300]!, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: const Text('Детали'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: const Text('Подтвердить получение'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final _DriverExpense expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(expense.icon, color: const Color(0xFF0065FF), size: 22.w),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  expense.place,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  expense.time,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            expense.amount,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverPayment {
  const _DriverPayment({
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.statusColor,
  });

  final String title;
  final String amount;
  final String dueDate;
  final Color statusColor;
}

class _DriverExpense {
  const _DriverExpense({
    required this.title,
    required this.amount,
    required this.place,
    required this.time,
    required this.icon,
  });

  final String title;
  final String amount;
  final String place;
  final String time;
  final IconData icon;
}
