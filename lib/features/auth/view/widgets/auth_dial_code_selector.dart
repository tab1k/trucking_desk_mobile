import 'package:country_code_picker/country_code_picker.dart'
    show CountryCode, codes;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Compact country dial code selector tailored for auth inputs.
class AuthDialCodeSelector extends StatelessWidget {
  const AuthDialCodeSelector({
    super.key,
    required this.currentDialCode,
    required this.onDialCodeChanged,
    this.icon,
  });

  final String currentDialCode;
  final ValueChanged<String> onDialCodeChanged;
  final IconData? icon;

  static final List<CountryCode> _countries =
      codes.map((json) => CountryCode.fromJson(json)).toList();

  Future<void> _openPicker(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final searchController = TextEditingController();
    List<CountryCode> filtered = List.of(_countries);

    final selected = await showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final mediaQuery = MediaQuery.of(context);
            final bottomPadding = mediaQuery.padding.bottom;
            final keyboardPadding = mediaQuery.viewInsets.bottom;

            void applyFilter(String value) {
              final query = value.trim().toUpperCase();
              setState(() {
                filtered =
                    _countries.where((country) {
                      final name = (country.name ?? '').toUpperCase();
                      final code = (country.code ?? '').toUpperCase();
                      final dial = (country.dialCode ?? '').toUpperCase();
                      return name.contains(query) ||
                          code.contains(query) ||
                          dial.contains(query);
                    }).toList();
              });
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardPadding),
              child: Container(
                
                child: FractionallySizedBox(
                  heightFactor: 0.75,
                  child: Material(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),
                        Container(
                          width: 44.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Выбор кода страны',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 20.sp,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: applyFilter,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 18.sp,
                                color: Colors.grey.shade500,
                              ),
                              hintText: 'Страна или код',
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withOpacity(
                                0.35,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                  
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.r),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child:
                              filtered.isEmpty
                                  ? Center(
                                    child: Text(
                                      'Ничего не найдено',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  )
                                  : ListView.separated(
                                    padding: EdgeInsets.only(bottom: 16.h),
                                    itemBuilder: (context, index) {
                                      final country = filtered[index];
                                      final isActive =
                                          country.dialCode == currentDialCode;
                                      return ListTile(
                                        onTap:
                                            () => Navigator.of(
                                              context,
                                            ).pop<CountryCode>(country),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 6.h,
                                        ),
                                        title: Text(
                                          '${country.dialCode ?? ''} '
                                          '${country.name ?? ''}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontWeight:
                                                isActive
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                        trailing:
                                            isActive
                                                ? Icon(
                                                  Icons.check_rounded,
                                                  color: colorScheme.primary,
                                                  size: 20.sp,
                                                )
                                                : null,
                                      );
                                    },
                                    separatorBuilder:
                                        (_, __) => Divider(
                                          height: 1,
                                          color: Colors.grey.shade200,
                                        ),
                                    itemCount: filtered.length,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final dialCode = selected?.dialCode;
    if (dialCode != null && dialCode != currentDialCode) {
      onDialCodeChanged(dialCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = Colors.grey.shade300;
    final textStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    );
    return IntrinsicHeight(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentDialCode, style: textStyle),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16.w,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 24.h, color: dividerColor),
            if (icon != null) ...[
              SizedBox(width: 8.w),
              Icon(icon, color: Colors.grey.shade500, size: 20.w),
            ],
          ],
        ),
      ),
    );
  }
}
