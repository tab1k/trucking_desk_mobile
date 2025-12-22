import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fura24.kz/shared/widgets/single_appbar.dart';

class DriverMessagesPage extends StatelessWidget {
  const DriverMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SingleAppbar(title: 'Сообщения'),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Блок сообщений с диспетчером появится позже. Пока заглушка.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
