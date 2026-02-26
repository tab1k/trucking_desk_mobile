import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthLanguageSelector extends StatefulWidget {
  const AuthLanguageSelector({super.key});

  @override
  State<AuthLanguageSelector> createState() => _AuthLanguageSelectorState();
}

class _AuthLanguageSelectorState extends State<AuthLanguageSelector> {
  static const _locales = <_LocaleOption>[
    _LocaleOption(locale: Locale('ru'), label: 'Русский'),
    _LocaleOption(locale: Locale('kk'), label: 'Қазақша'),
    _LocaleOption(locale: Locale('en'), label: 'English'),
    _LocaleOption(locale: Locale('zh'), label: '中文'),
  ];

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showLanguageSheet(context),
      icon: Icon(Icons.language, color: Colors.black87, size: 24.w),
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final current = context.locale;
    final selected = await showModalBottomSheet<_LocaleOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 12.h),
                ..._locales.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: option.locale.languageCode == current.languageCode
                        ? Icon(
                            Icons.radio_button_checked,
                            color: const Color(0xFF64B5F6),
                            size: 24.w,
                          )
                        : Icon(Icons.radio_button_off, size: 24.w),
                    onTap: () => Navigator.of(context).pop(option),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await context.setLocale(selected.locale);
    }
  }
}

class _LocaleOption {
  const _LocaleOption({required this.locale, required this.label});
  final Locale locale;
  final String label;
}
