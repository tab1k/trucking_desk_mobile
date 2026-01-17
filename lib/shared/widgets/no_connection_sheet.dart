import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class NoConnectionSheet extends StatelessWidget {
  const NoConnectionSheet({
    super.key,
    required this.isServerError,
    this.onRetry,
  });

  final bool isServerError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),
          SizedBox(height: 32.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isServerError ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
              size: 48.w,
              color: const Color(0xFFFF5252),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            isServerError
                ? 'Сервер временно недоступен'
                : 'Нет соединения с интернетом',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            isServerError
                ? 'Мы уже работаем над устранением проблемы. Пожалуйста, попробуйте позже.'
                : 'Проверьте настройки сети или подключитесь к Wi-Fi и попробуйте снова.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                onRetry?.call();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Понятно',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
