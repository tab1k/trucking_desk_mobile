import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class HomeCalculateCard extends StatelessWidget {
  const HomeCalculateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.15),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Расчитать примерную стомость',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Расчитайте примерную стомость услуги перевозки за ваш груз.',
                  style: TextStyle(
                    fontSize: 12.h,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: SvgPicture.asset(
              'assets/svg/truck-loading.svg',
              width: 21.r,
              height: 21.r,
            ),
          ),
        ],
      ),
    );
  }
}
